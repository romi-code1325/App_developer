import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/tracking.dart';

/// Dart side of the Flutter <-> Kotlin bridge.
///
///  * MethodChannel (Flutter -> native): start / processFrame / stop
///  * EventChannel  (native -> Flutter): stream of [TrackingResult]
class FaceTrackingService {
  static const MethodChannel _method = MethodChannel('virtual_tryon/face_tracker');
  static const EventChannel _events = EventChannel('virtual_tryon/face_events');

  Stream<TrackingResult>? _results;

  Stream<TrackingResult> get results => _results ??= _events
      .receiveBroadcastStream()
      .map((e) => TrackingResult.fromMap(Map<Object?, Object?>.from(e as Map)));

  Future<void> start() => _method.invokeMethod<void>('start');

  Future<void> stop() async {
    try {
      await _method.invokeMethod<void>('stop');
    } on PlatformException {
      // Nothing useful to do while shutting down.
    }
  }

  /// Sends one NV21 frame to the native detector. Completes once the native
  /// side has finished, which gives natural back-pressure: the caller simply
  /// skips camera frames while a previous one is still in flight.
  Future<bool> processFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rotation,
  }) async {
    try {
      final ok = await _method.invokeMethod<bool>('processFrame', {
        'bytes': bytes,
        'width': width,
        'height': height,
        'rotation': rotation,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }
}
