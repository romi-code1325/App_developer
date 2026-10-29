package com.example.virtual_tryon

import android.graphics.PointF
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions
import com.google.mlkit.vision.face.FaceLandmark
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native face tracking for the try-on screen.
 *
 *  MethodChannel "virtual_tryon/face_tracker"  (Flutter -> Kotlin)
 *      start()                        create the ML Kit detector
 *      processFrame(bytes,w,h,rot)    run detection on one NV21 frame
 *      stop()                         release the detector
 *
 *  EventChannel "virtual_tryon/face_events"    (Kotlin -> Flutter)
 *      emits one map per processed frame: image size + list of faces
 */
class FaceTrackerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "virtual_tryon/face_tracker"
        const val EVENT_CHANNEL = "virtual_tryon/face_events"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var detector: FaceDetector? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopDetector()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ---- EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // ---- MethodChannel.MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                startDetector()
                result.success(null)
            }
            "processFrame" -> processFrame(call, result)
            "stop" -> {
                stopDetector()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startDetector() {
        if (detector != null) return
        val options = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL) // eyes -> position/scale/roll
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .setMinFaceSize(0.15f)
            .enableTracking()
            .build()
        detector = FaceDetection.getClient(options)
    }

    private fun stopDetector() {
        detector?.close()
        detector = null
    }

    private fun processFrame(call: MethodCall, result: MethodChannel.Result) {
        val det = detector
        if (det == null) {
            result.error("NOT_STARTED", "Call start() before processFrame()", null)
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val rotation = call.argument<Int>("rotation")
        if (bytes == null || width == null || height == null || rotation == null) {
            result.error("BAD_ARGS", "bytes, width, height and rotation are required", null)
            return
        }

        val image = InputImage.fromByteArray(
            bytes, width, height, rotation, InputImage.IMAGE_FORMAT_NV21
        )
        // ML Kit returns coordinates in the *rotated* (upright) frame.
        val upright = rotation == 90 || rotation == 270
        val outW = if (upright) height else width
        val outH = if (upright) width else height

        det.process(image)
            .addOnSuccessListener { faces ->
                eventSink?.success(buildPayload(faces, outW, outH))
                result.success(true)
            }
            .addOnFailureListener { e ->
                result.error("DETECTION_FAILED", e.message, null)
            }
    }

    private fun buildPayload(faces: List<Face>, w: Int, h: Int): Map<String, Any?> = mapOf(
        "imageWidth" to w,
        "imageHeight" to h,
        "timestamp" to System.currentTimeMillis(),
        "faces" to faces.map { f ->
            mapOf(
                "left" to f.boundingBox.left,
                "top" to f.boundingBox.top,
                "right" to f.boundingBox.right,
                "bottom" to f.boundingBox.bottom,
                "eulerX" to f.headEulerAngleX, // pitch
                "eulerY" to f.headEulerAngleY, // yaw
                "eulerZ" to f.headEulerAngleZ, // roll
                "leftEye" to point(f.getLandmark(FaceLandmark.LEFT_EYE)?.position),
                "rightEye" to point(f.getLandmark(FaceLandmark.RIGHT_EYE)?.position),
                "trackingId" to f.trackingId
            )
        }
    )

    private fun point(p: PointF?): Map<String, Double>? =
        p?.let { mapOf("x" to it.x.toDouble(), "y" to it.y.toDouble()) }
}
