import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/face_pose.dart';
import '../../models/frame_model.dart';
import '../../state/try_on_controller.dart';
import 'spectacle_painter.dart';

/// Places the selected frame on the face.
///
/// This widget lives inside the same FittedBox as the camera preview and is
/// sized to the camera image, so pose coordinates (image pixels) map 1:1 to
/// layout coordinates; the FittedBox handles screen scaling for both.
class GlassesOverlay extends StatelessWidget {
  const GlassesOverlay({super.key});

  static const double _perspective = 0.0012;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TryOnController>();
    final frame = context.select<TryOnController, FrameModel>((c) => c.selected);
    final debug = context.select<TryOnController, bool>((c) => c.showDebug);

    return ValueListenableBuilder<FacePose?>(
      valueListenable: controller.pose,
      builder: (context, pose, _) {
        if (pose == null) return const SizedBox.expand();

        const w = 220.0, h = 90.0;
        final scale = pose.eyeDistance / SpectaclePainter.eyeSpan;
        // Fade out when the head is turned far away from the camera.
        final opacity = (1 - ((pose.yaw.abs() - 0.6) / 0.4)).clamp(0.0, 1.0);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, _perspective)
          ..rotateZ(pose.roll) // head tilt
          ..rotateX(pose.pitch * 0.8) // nod up / down
          ..rotateY(pose.yaw * 0.9); // turn left / right

        return RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (debug) CustomPaint(painter: _DebugPainter(pose)),
              Positioned(
                left: pose.center.dx - w / 2,
                top: pose.center.dy - h / 2,
                width: w,
                height: h,
                child: Transform.scale(
                  scale: scale, // distance from camera
                  child: Opacity(
                    opacity: opacity,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: transform,
                      child: CustomPaint(
                        size: const Size(w, h),
                        painter: SpectaclePainter(frame),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DebugPainter extends CustomPainter {
  _DebugPainter(this.pose);
  final FacePose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.greenAccent;
    canvas.drawRect(pose.bounds, line);
    canvas.drawCircle(pose.center, 4, Paint()..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(_DebugPainter old) => old.pose != pose;
}
