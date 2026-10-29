import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_tryon/models/face_pose.dart';
import 'package:virtual_tryon/models/tracking.dart';

void main() {
  const image = Size(480, 640);

  TrackedFace face({Offset? l, Offset? r}) => TrackedFace(
        bounds: const Rect.fromLTRB(150, 200, 330, 420),
        eulerX: 0,
        eulerY: 10,
        eulerZ: 0,
        leftEye: l,
        rightEye: r,
      );

  test('eye midpoint, distance and roll are derived from the eyes', () {
    final pose = FacePose.fromFace(
      face(l: const Offset(200, 300), r: const Offset(280, 320)),
      image,
      mirror: false,
    );
    expect(pose.center, const Offset(240, 310));
    expect(pose.eyeDistance, closeTo(math.sqrt(80 * 80 + 20 * 20), 1e-9));
    expect(pose.roll, closeTo(math.atan2(20, 80), 1e-9));
  });

  test('mirroring flips x around the image width', () {
    final pose = FacePose.fromFace(
      face(l: const Offset(200, 300), r: const Offset(280, 300)),
      image,
      mirror: true,
    );
    expect(pose.center.dx, closeTo(480 - 240, 1e-9));
    expect(pose.roll, closeTo(0, 1e-9));
    // Yaw sign is inverted for the mirrored preview.
    expect(pose.yaw, lessThan(0));
  });

  test('falls back to the bounding box when landmarks are missing', () {
    final pose = FacePose.fromFace(face(), image, mirror: false);
    expect(pose.center.dx, 240);
    expect(pose.eyeDistance, closeTo(180 * 0.42, 1e-9));
  });

  test('lerp with t=1 returns the target pose', () {
    final a = FacePose.fromFace(
        face(l: const Offset(100, 100), r: const Offset(160, 100)), image,
        mirror: false);
    final b = FacePose.fromFace(
        face(l: const Offset(200, 300), r: const Offset(280, 300)), image,
        mirror: false);
    expect(a.lerp(b, 1).center, b.center);
  });
}
