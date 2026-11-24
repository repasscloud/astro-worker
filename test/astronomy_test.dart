import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/astrology.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = MeeusEngine();

  test('known Julian day and explicit UTC bounds', () {
    expect(MeeusEngine.utcJulianDay(DateTime.utc(2000, 1, 1, 12)), 2451545.0);
    expect(
      () => engine.skyAt(engine.start.subtract(const Duration(seconds: 1))),
      throwsRangeError,
    );
    expect(() => engine.skyAt(engine.end), throwsRangeError);
    expect(engine.skyAt(engine.start).positions.length, Body.values.length);
  });

  test('lunar phase instants agree with independent USNO 2025 reference', () {
    // https://aa.usno.navy.mil/api/moon/phases/year?year=2025
    final fixtures = {
      'First Quarter': DateTime.utc(2025, 1, 6, 23, 56),
      'Full Moon': DateTime.utc(2025, 1, 13, 22, 27),
      'Last Quarter': DateTime.utc(2025, 1, 21, 20, 31),
      'New Moon': DateTime.utc(2025, 1, 29, 12, 36),
    };
    final events = engine.events(DateTime.utc(2025, 1), DateTime.utc(2025, 2));
    for (final MapEntry(key: phase, value: expected) in fixtures.entries) {
      final event = events.singleWhere((event) => event.name == phase);
      expect(
        event.instant.difference(expected).inSeconds.abs(),
        lessThanOrEqualTo(120),
        reason: phase,
      );
    }
    final full = engine.skyAt(fixtures['Full Moon']!);
    expect(full.phase, 'Full Moon');
    expect(full.illumination, greaterThan(0.99));
    expect(full.lunarAgeDays, closeTo(14, 2));
  });

  test('lunar apparent position and illumination match JPL Horizons', () {
    // Horizons observer table, target 301, geocentre 500@399,
    // quantities 2,10,20,31, 2025-01-13 22:27 UTC.
    final sky = engine.skyAt(DateTime.utc(2025, 1, 13, 22, 27));
    final moon = sky.positions[Body.moon]!;
    expect(moon.longitude, closeTo(113.9966965, 0.02));
    expect(moon.latitude, closeTo(4.5953613, 0.02));
    expect(
      moon.rightAscension,
      closeTo((7 + 47 / 60 + 4.31 / 3600) * 15, 0.02),
    );
    expect(moon.declination, closeTo(25 + 49 / 60 + 52.9 / 3600, 0.02));
    expect(moon.distanceKm, closeTo(0.00254960799757 * 149597870.7, 50));
    expect(sky.illumination * 100, closeTo(99.84009, 0.05));
  });

  test(
    'calendar includes season, unique phase events, eclipses and apsides',
    () {
      final values = engine.events(DateTime.utc(2025), DateTime.utc(2026));
      expect(
        values.where((event) => event.category == EventCategory.season).length,
        4,
      );
      expect(
        values.where((event) => event.category == EventCategory.eclipse).length,
        4,
      );
      expect(
        values
            .where((event) => event.category == EventCategory.moonPhase)
            .length,
        inInclusiveRange(48, 51),
      );
      expect(
        values.where((event) => event.category == EventCategory.apsis).length,
        inInclusiveRange(24, 29),
      );
    },
  );

  test('zodiac and aspects wrap through zero degrees', () {
    CelestialPosition position(Body body, double longitude, double speed) =>
        CelestialPosition(
          body: body,
          longitude: longitude,
          speed: speed,
          latitude: 0,
          rightAscension: 0,
          declination: 0,
        );
    final sun = position(Body.sun, 359.75, 1);
    final moon = position(Body.moon, 0.25, 13);
    expect(sun.sign(), 'Pisces');
    expect(moon.sign(), 'Aries');
    expect(moon.zodiacPosition(), '0° 15′ 0″');
    final active = activeAspects(
      SkySnapshot({Body.sun: sun, Body.moon: moon}, 0.5, 0, null),
      1,
    );
    expect(active.single.aspect, MajorAspect.conjunction);
    expect(active.single.orb, 0.5);
    expect(active.single.motion, 'Separating');
  });
}
