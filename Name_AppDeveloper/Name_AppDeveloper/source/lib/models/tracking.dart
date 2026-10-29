import 'dart:ui';

/// One face as reported by the native ML Kit detector.
/// All coordinates are in the *upright, un-mirrored* camera image space.
class TrackedFace {
  const TrackedFace({
    required this.bounds,
    required this.eulerX,
    required this.eulerY,
    required this.eulerZ,
    this.leftEye,
    this.rightEye,
    this.trackingId,
  });

  final Rect bounds;

  /// Pitch / yaw / roll in degrees.
  final double eulerX;
  final double eulerY;
  final double eulerZ;
  final Offset? leftEye;
  final Offset? rightEye;
  final int? trackingId;

  factory TrackedFace.fromMap(Map<Object?, Object?> m) {
    double d(String k) => (m[k] as num).toDouble();
    Offset? pt(Object? v) {
      if (v is! Map) return null;
      return Offset((v['x'] as num).toDouble(), (v['y'] as num).toDouble());
    }

    return TrackedFace(
      bounds: Rect.fromLTRB(d('left'), d('top'), d('right'), d('bottom')),
      eulerX: d('eulerX'),
      eulerY: d('eulerY'),
      eulerZ: d('eulerZ'),
      leftEye: pt(m['leftEye']),
      rightEye: pt(m['rightEye']),
      trackingId: m['trackingId'] as int?,
    );
  }
}

class TrackingResult {
  const TrackingResult({required this.imageSize, required this.faces});

  final Size imageSize;
  final List<TrackedFace> faces;

  factory TrackingResult.fromMap(Map<Object?, Object?> m) {
    return TrackingResult(
      imageSize: Size(
        (m['imageWidth'] as num).toDouble(),
        (m['imageHeight'] as num).toDouble(),
      ),
      faces: (m['faces'] as List)
          .map((e) => TrackedFace.fromMap(Map<Object?, Object?>.from(e as Map)))
          .toList(),
    );
  }

  /// The closest face to the camera (largest bounding box).
  TrackedFace? get largestFace {
    if (faces.isEmpty) return null;
    return faces.reduce((a, b) =>
        a.bounds.width * a.bounds.height >= b.bounds.width * b.bounds.height
            ? a
            : b);
  }
}
