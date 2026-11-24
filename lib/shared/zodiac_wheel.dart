import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/astronomy.dart';
import '../domain/astrology.dart';

class ZodiacWheel extends StatelessWidget {
  const ZodiacWheel({
    super.key,
    required this.sky,
    required this.offset,
    required this.aspects,
  });

  final SkySnapshot sky;
  final double offset;
  final List<ActiveAspect> aspects;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: AspectRatio(
        aspectRatio: 1,
        child: Semantics(
          image: true,
          label: 'Diagram of the zodiac positions and active aspects listed below.',
          child: CustomPaint(
            painter: _ZodiacPainter(
              sky,
              offset,
              aspects,
              Theme.of(context).colorScheme,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ZodiacPainter extends CustomPainter {
  _ZodiacPainter(this.sky, this.offset, this.aspects, this.colours);

  final SkySnapshot sky;
  final double offset;
  final List<ActiveAspect> aspects;
  final ColorScheme colours;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    Offset point(double longitude, double fraction) {
      final angle = math.pi - longitude * math.pi / 180;
      return center +
          Offset(math.cos(angle), math.sin(angle)) * radius * fraction;
    }

    final outline = Paint()
      ..color = colours.outline
      ..style = PaintingStyle.stroke;
    for (final fraction in [1.0, .76]) {
      canvas.drawCircle(center, radius * fraction, outline);
    }
    for (var index = 0; index < zodiacSigns.length; index++) {
      final longitude = index * 30.0;
      canvas.drawLine(point(longitude, .76), point(longitude, 1), outline);
      final text = TextPainter(
        text: TextSpan(
          text: zodiacSigns[index].substring(0, 3),
          style: TextStyle(color: colours.onSurface, fontSize: radius * .085),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        point(longitude + 15, .88) - text.size.center(Offset.zero),
      );
      text.dispose();
    }

    final planetPositions = {
      for (final planet in sky.positions.values)
        planet.body: point(planet.longitude - offset, .72),
    };
    final line = Paint()..color = colours.tertiary.withValues(alpha: .48);
    for (final aspect in aspects) {
      canvas.drawLine(
        planetPositions[aspect.first]!,
        planetPositions[aspect.second]!,
        line,
      );
    }
    final dot = Paint()..color = colours.primary;
    for (final position in planetPositions.values) {
      canvas.drawCircle(position, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_ZodiacPainter oldDelegate) =>
      oldDelegate.sky != sky ||
      oldDelegate.offset != offset ||
      oldDelegate.aspects != aspects ||
      oldDelegate.colours != colours;
}
