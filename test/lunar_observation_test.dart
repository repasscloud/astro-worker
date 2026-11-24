import 'dart:math' as math;

import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/astrology.dart';
import 'package:astro_worker/domain/horizon.dart';
import 'package:astro_worker/domain/lunar_observation.dart';
import 'package:astro_worker/domain/planetary_events.dart';
import 'package:astro_worker/domain/zodiac.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime.utc(2025, 1, 1);
final _end = DateTime.utc(2025, 1, 3);

class _Fixture implements PlanetaryEventEngine, RelativeLongitudeEngine {
  @override
  List<PlanetaryEvent> planetaryEvents(
    Body body,
    DateTime from,
    DateTime until, {
    Zodiac zodiac = Zodiac.tropical,
  }) => [
    (
      instant: _start,
      kind: PlanetaryEventKind.ingress,
      sign: 'Aries',
      retrograde: false,
    ),
    (
      instant: _end,
      kind: PlanetaryEventKind.ingress,
      sign: 'Taurus',
      retrograde: false,
    ),
  ];

  @override
  double relativeLongitude(Body first, Body second, DateTime instant) {
    final elapsed = instant.difference(_start).inMilliseconds / 3600000;
    return switch (second) {
      Body.sun => elapsed - 5,
      Body.uranus => elapsed - 25,
      _ => 42,
    };
  }
}

void main() {
  final engine = MeeusEngine();

  test('January apsides agree with published minute-resolution references', () {
    final apsides = engine
        .events(DateTime.utc(2025), DateTime.utc(2025, 2))
        .where((event) => event.category == EventCategory.apsis)
        .toList();
    final expected = {
      'Lunar perigee': DateTime.utc(2025, 1, 7, 23, 34),
      'Lunar apogee': DateTime.utc(2025, 1, 21, 4, 55),
    };
    expect(apsides.map((event) => event.name), orderedEquals(expected.keys));
    for (final event in apsides) {
      expect(
        event.instant.difference(expected[event.name]!).abs(),
        lessThan(const Duration(minutes: 3)),
      );
    }
  });

  test('January 2025 bright-limb angle agrees with AstroPixels DE405', () {
    final sky = engine.skyAt(DateTime.utc(2025, 1, 13));
    final angle = brightLimbPositionAngle(
      sky.positions[Body.sun]!,
      sky.positions[Body.moon]!,
    );
    expect(normalize(angle * 180 / math.pi), closeTo(297.5, .3));
  });

  test('observer orientation is undefined when the Moon is at zenith', () {
    final now = DateTime.utc(2025, 1, 13);
    final sky = engine.skyAt(now);
    final moon = sky.positions[Body.moon]!;
    final sun = sky.positions[Body.sun]!;
    expect(
      lunarRotationForObserver(
        sun,
        moon,
        moon.rightAscension * math.pi / 180,
        Observer(latitude: moon.declination, longitude: 0),
      ),
      isNull,
    );
    final north = engine.lunarRotation(
      now,
      sky,
      Observer(latitude: 45, longitude: 0),
    )!;
    final south = engine.lunarRotation(
      now,
      sky,
      Observer(latitude: -45, longitude: 0),
    )!;
    expect(signedAngle((north - south) * 180 / math.pi).abs(), greaterThan(80));
  });

  test(
    'traditional rules select the final included hit before the ingress',
    () {
      final fixture = _Fixture();
      for (final rule in VoidOfCourseRule.values) {
        final window = lunarVoidOfCourse(
          instant: DateTime.utc(2025, 1, 2),
          zodiac: Zodiac.tropical,
          rule: rule,
          ingresses: fixture,
          positions: fixture,
        )!;
        expect(
          window.start,
          _start.add(
            Duration(hours: rule == VoidOfCourseRule.classical ? 5 : 25),
          ),
        );
        expect(window.end, _end);
        expect(window.sign, 'Aries');
      }
    },
  );
}
