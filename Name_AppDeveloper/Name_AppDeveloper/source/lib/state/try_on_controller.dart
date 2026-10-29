import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/face_pose.dart';
import '../models/frame_model.dart';
import '../models/tracking.dart';
import '../services/face_tracking_service.dart';

enum TryOnStatus { initializing, ready, permissionDenied, error }

/// Owns the camera, the native tracker and the try-on state.
///
/// Two kinds of state, deliberately separated for performance:
///  * coarse state (status, selected frame, debug flag) -> notifyListeners()
///  * the per-frame face pose (~30 Hz)                  -> [pose] ValueNotifier,
///    so only the overlay repaints, not the whole screen.
class TryOnController extends ChangeNotifier with WidgetsBindingObserver {
  TryOnController({FaceTrackingService? service})
      : _service = service ?? FaceTrackingService();

  /// The Android front-camera preview is shown mirrored (selfie style).
  /// Flip this if the glasses ever look mirrored on a particular device.
  static const bool previewMirrored = true;
  static const double _smoothing = 0.55;
  static const int _missesBeforeHide = 6;

  final FaceTrackingService _service;
  final ValueNotifier<FacePose?> pose = ValueNotifier<FacePose?>(null);

  CameraController? camera;
  TryOnStatus status = TryOnStatus.initializing;
  String? errorMessage;
  FrameModel selected = kFrames.first;
  bool showDebug = false;

  CameraDescription? _description;
  StreamSubscription<TrackingResult>? _subscription;
  bool _busy = false;
  bool _disposed = false;
  int _misses = 0;
  FacePose? _smoothed;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _startCamera();
  }

  Future<void> retry() => _startCamera();

  void selectFrame(FrameModel frame) {
    if (frame == selected) return;
    selected = frame;
    notifyListeners(); // overlay picks it up on the very next build
  }

  void toggleDebug() {
    showDebug = !showDebug;
    notifyListeners();
  }

  // ---------------------------------------------------------------- camera

  Future<void> _startCamera() async {
    await _stopCamera();
    if (_disposed) return;
    status = TryOnStatus.initializing;
    errorMessage = null;
    _safeNotify();

    try {
      final cameras = await availableCameras();
      final description = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.medium, // 640x480: plenty for ML Kit, cheap to copy
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }

      await _service.start();
      _subscription = _service.results.listen(_onResult);
      await controller.startImageStream(_onCameraImage);

      camera = controller;
      _description = description;
      status = TryOnStatus.ready;
    } on CameraException catch (e) {
      status = e.code.startsWith('CameraAccess')
          ? TryOnStatus.permissionDenied
          : TryOnStatus.error;
      errorMessage = e.description ?? e.code;
    } catch (e) {
      status = TryOnStatus.error;
      errorMessage = e.toString();
    }
    _safeNotify();
  }

  Future<void> _stopCamera() async {
    await _subscription?.cancel();
    _subscription = null;
    final controller = camera;
    camera = null;
    if (!_disposed) pose.value = null;
    _smoothed = null;
    _busy = false;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}
      await controller.dispose();
    }
    await _service.stop();
  }

  void _onCameraImage(CameraImage image) {
    if (_busy || _disposed) return;
    final description = _description;
    if (description == null) return;
    _busy = true;
    _service
        .processFrame(
          bytes: _toNv21(image),
          width: image.width,
          height: image.height,
          // App is locked to portrait, so the rotation needed to make the
          // frame upright equals the sensor orientation.
          rotation: description.sensorOrientation,
        )
        .whenComplete(() => _busy = false);
  }

  /// Camera2 delivers NV21 as a single plane; the YUV_420 fallback is only
  /// here so unusual devices degrade gracefully instead of crashing.
  Uint8List _toNv21(CameraImage image) {
    if (image.planes.length == 1) return image.planes[0].bytes;

    final w = image.width, h = image.height;
    final y = image.planes[0], u = image.planes[1], v = image.planes[2];
    final out = Uint8List(w * h * 3 ~/ 2);
    var idx = 0;
    for (var row = 0; row < h; row++) {
      out.setRange(idx, idx + w, y.bytes, row * y.bytesPerRow);
      idx += w;
    }
    final pixelStride = u.bytesPerPixel ?? 1;
    for (var row = 0; row < h ~/ 2; row++) {
      for (var col = 0; col < w ~/ 2; col++) {
        final i = row * u.bytesPerRow + col * pixelStride;
        out[idx++] = v.bytes[i];
        out[idx++] = u.bytes[i];
      }
    }
    return out;
  }

  // -------------------------------------------------------------- tracking

  void _onResult(TrackingResult result) {
    final face = result.largestFace;
    if (face == null) {
      // Tolerate a few dropped detections so the glasses don't flicker.
      if (++_misses >= _missesBeforeHide) {
        _smoothed = null;
        pose.value = null;
      }
      return;
    }
    _misses = 0;
    final raw = FacePose.fromFace(face, result.imageSize, mirror: previewMirrored);
    _smoothed = _smoothed == null ? raw : _smoothed!.lerp(raw, _smoothing);
    pose.value = _smoothed;
  }

  // ------------------------------------------------------------- lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera().then((_) {
        status = TryOnStatus.initializing;
        _safeNotify();
      });
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    pose.dispose();
    super.dispose();
  }
}
