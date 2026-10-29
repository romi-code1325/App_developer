import 'dart:math' as math;
import 'dart:ui' as ui;

import 'tracking.dart';

/// Face pose expressed in *preview space* (mirroring already applied), ready
/// to drive the glasses overlay. Angles are radians.
class FacePose {
  const FacePose({
    required this.center,
    required this.eyeDistance,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.bounds,
  });

  /// Midpoint between the eyes.
  final ui.Offset center;

  /// Inter-pupillary distance in image pixels: drives the frame's scale,
  /// which makes it track the user's distance from the camera.
  final double eyeDistance;
  final double yaw;
  final double pitch;
  final double roll;
  final ui.Rect bounds;

  static const double _deg = math.pi / 180;

  static FacePose fromFace(
    TrackedFace f,
    ui.Size image, {
    required bool mirror,
  }) {
    ui.Offset flip(ui.Offset p) => mirror ? ui.Offset(image.width - p.dx, p.dy) : p;

    final b = f.bounds;
    final bounds = mirror
        ? ui.Rect.fromLTRB(image.width - b.right, b.top, image.width - b.left, b.bottom)
        : b;

    ui.Offset center;
    double eyeDistance;
    double roll;

    if (f.leftEye != null && f.rightEye != null) {
      var a = flip(f.leftEye!);
      var c = flip(f.rightEye!);
      if (a.dx > c.dx) {
        final t = a;
        a = c;
        c = t;
      }
      center = (a + c) / 2;
      eyeDistance = (c - a).distance;
      // Roll straight from the eye line: no sign convention to get wrong.
      roll = math.atan2(c.dy - a.dy, c.dx - a.dx);
    } else {
      // Fallback when landmarks are missing: estimate from the bounding box.
      center = ui.Offset(bounds.center.dx, bounds.top + bounds.height * 0.40);
      eyeDistance = bounds.width * 0.42;
      final z = f.eulerZ * _deg;
      roll = mirror ? z : -z;
    }

    final yawDeg = mirror ? -f.eulerY : f.eulerY;
    return FacePose(
      center: center,
      eyeDistance: eyeDistance,
      yaw: yawDeg.clamp(-60.0, 60.0).toDouble() * _deg,
      pitch: f.eulerX.clamp(-40.0, 40.0).toDouble() * _deg,
      roll: roll,
      bounds: bounds,
    );
  }

  /// Exponential smoothing step (t = 1 means "take the new value").
  FacePose lerp(FacePose o, double t) => FacePose(
        center: ui.Offset.lerp(center, o.center, t)!,
        eyeDistance: ui.lerpDouble(eyeDistance, o.eyeDistance, t)!,
        yaw: ui.lerpDouble(yaw, o.yaw, t)!,
        pitch: ui.lerpDouble(pitch, o.pitch, t)!,
        roll: ui.lerpDouble(roll, o.roll, t)!,
        bounds: ui.Rect.lerp(bounds, o.bounds, t)!,
      );
}
