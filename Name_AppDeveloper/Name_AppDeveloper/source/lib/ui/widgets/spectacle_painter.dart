import 'package:flutter/material.dart';

import '../../models/frame_model.dart';

/// Draws a spectacle frame in a fixed 220 x 90 design space.
///
/// Both lens centres sit on the horizontal midline, exactly [eyeSpan] apart
/// (design units). That is what lets the overlay scale the drawing by
/// `eyeDistance / eyeSpan` so the lenses land on the user's pupils.
class SpectaclePainter extends CustomPainter {
  const SpectaclePainter(this.frame);

  final FrameModel frame;

  static const Size designSize = Size(220, 90);
  static const double eyeSpan = 100;
  static const Offset _l = Offset(60, 45);
  static const Offset _r = Offset(160, 45);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / designSize.width, size.height / designSize.height);

    switch (frame.shape) {
      case FrameShape.round:
        _round(canvas);
      case FrameShape.wayfarer:
        _wayfarer(canvas);
      case FrameShape.aviator:
        _aviator(canvas);
      case FrameShape.catEye:
        _catEye(canvas);
    }
    canvas.restore();
  }

  Paint _stroke(double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = frame.color;

  Paint get _tint => Paint()..color = frame.lensTint;

  void _lens(Canvas c, Path p, double w, {Paint? fill}) {
    c.drawPath(p, fill ?? _tint);
    c.drawPath(p, _stroke(w));
  }

  void _line(Canvas c, Offset a, Offset b, double w) =>
      c.drawLine(a, b, _stroke(w));

  void _round(Canvas c) {
    for (final o in [_l, _r]) {
      _lens(c, Path()..addOval(Rect.fromCircle(center: o, radius: 33)), 4);
    }
    c.drawPath(
      Path()
        ..moveTo(93, 40)
        ..quadraticBezierTo(110, 27, 127, 40),
      _stroke(4),
    );
    _line(c, const Offset(27, 40), const Offset(6, 36), 4);
    _line(c, const Offset(193, 40), const Offset(214, 36), 4);
  }

  void _wayfarer(Canvas c) {
    for (final o in [_l, _r]) {
      final rr = RRect.fromRectAndCorners(
        Rect.fromCenter(center: o, width: 86, height: 58),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: const Radius.circular(26),
        bottomRight: const Radius.circular(26),
      );
      _lens(c, Path()..addRRect(rr), 7);
    }
    _line(c, const Offset(103, 34), const Offset(117, 34), 7);
    _line(c, const Offset(17, 33), const Offset(3, 31), 7);
    _line(c, const Offset(203, 33), const Offset(217, 31), 7);
  }

  Path _drop(Offset o) => Path()
    ..moveTo(o.dx - 42, o.dy - 23)
    ..quadraticBezierTo(o.dx, o.dy - 35, o.dx + 42, o.dy - 23)
    ..cubicTo(o.dx + 47, o.dy + 5, o.dx + 22, o.dy + 31, o.dx, o.dy + 31)
    ..cubicTo(o.dx - 22, o.dy + 31, o.dx - 47, o.dy + 5, o.dx - 42, o.dy - 23)
    ..close();

  void _aviator(Canvas c) {
    for (final o in [_l, _r]) {
      final p = _drop(o);
      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [frame.lensTint, frame.lensTint.withAlpha(0x30)],
        ).createShader(p.getBounds());
      _lens(c, p, 3, fill: fill);
    }
    c.drawPath(
      Path()
        ..moveTo(101, 28)
        ..quadraticBezierTo(110, 22, 119, 28),
      _stroke(3),
    );
    _line(c, const Offset(103, 38), const Offset(117, 38), 3);
    _line(c, const Offset(18, 24), const Offset(4, 21), 3);
    _line(c, const Offset(202, 24), const Offset(216, 21), 3);
  }

  /// [o] is the outward direction: -1 for the left lens, +1 for the right.
  Path _cat(Offset c, double o) => Path()
    ..moveTo(c.dx - o * 40, c.dy - 12)
    ..lineTo(c.dx + o * 50, c.dy - 30)
    ..quadraticBezierTo(c.dx + o * 46, c.dy + 10, c.dx + o * 10, c.dy + 24)
    ..quadraticBezierTo(c.dx - o * 38, c.dy + 30, c.dx - o * 40, c.dy - 12)
    ..close();

  void _catEye(Canvas c) {
    _lens(c, _cat(_l, -1), 5);
    _lens(c, _cat(_r, 1), 5);
    _line(c, const Offset(100, 32), const Offset(120, 32), 5);
    _line(c, const Offset(10, 15), const Offset(2, 12), 5);
    _line(c, const Offset(210, 15), const Offset(218, 12), 5);
  }

  @override
  bool shouldRepaint(SpectaclePainter old) => old.frame != frame;
}
