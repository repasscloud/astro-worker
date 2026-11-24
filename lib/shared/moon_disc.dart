import 'dart:math' as math;

import 'package:flutter/material.dart';

class MoonDisc extends StatelessWidget {
  const MoonDisc({
    super.key,
    required this.illumination,
    required this.waxing,
    this.south = false,
  });
  final double illumination;
  final bool waxing;
  final bool south;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label:
        'Schematic lunar disc, ${(illumination * 100).round()} percent illuminated',
    child: CustomPaint(
      size: const Size.square(140),
      painter: _LunarPainter(illumination, waxing != south),
    ),
  );
}

class _LunarPainter extends CustomPainter {
  _LunarPainter(this.light, this.right);
  final double light;
  final bool right;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - 2;
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!right) canvas.scale(-1, 1);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = const Color(0xff35334a),
    );
    final path = Path()..moveTo(0, -radius);
    for (var i = 0; i <= 64; i++) {
      final phase = i * math.pi / 64;
      path.lineTo(radius * math.sin(phase), -radius * math.cos(phase));
    }
    for (var i = 64; i >= 0; i--) {
      final phase = i * math.pi / 64;
      path.lineTo(
        radius * (1 - 2 * light) * math.sin(phase),
        -radius * math.cos(phase),
      );
    }
    canvas.drawPath(path..close(), Paint()..color = const Color(0xffffe3a7));
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xffa398c5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LunarPainter oldDelegate) =>
      oldDelegate.light != light || oldDelegate.right != right;
}
