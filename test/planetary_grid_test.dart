import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = MeeusEngine();

  test(
    'apparent geocentric coordinates agree with the Horizons fixture grid',
    () {
      final observations = <DateTime, SkySnapshot>{};
      for (final (utc, body, longitude, latitude, distance, illumination)
          in _reference) {
        final instant = DateTime.parse(utc);
        final sky = observations.putIfAbsent(
          instant,
          () => engine.skyAt(instant),
        );
        final item = sky.positions[body]!;
        final reason = '${body.name} at $utc';
        expect(
          signedAngle(item.longitude - longitude).abs(),
          lessThan(.01),
          reason: reason,
        );
        expect(item.latitude, closeTo(latitude, .01), reason: reason);
        if (distance != null) {
          expect(
            item.distanceKm,
            closeTo(distance, body == Body.moon ? 50 : 10000),
            reason: reason,
          );
        }
        if (illumination != null) {
          expect(
            sky.illumination,
            closeTo(illumination, .0005),
            reason: reason,
          );
        }
      }
    },
  );
}

// NASA/JPL Horizons observer tables, Earth centre 500@399, quantities 31
// (apparent observer ecliptic longitude/latitude), plus 10 and 20 for Sun/Moon.
// UTC, angles in degrees, range in km, and illumination as a fraction.
const _reference = <(String, Body, double, double, double?, double?)>[
  ('2000-01-01T12:00:00Z', Body.jupiter, 25.2530685, -1.2621868, null, null),
  ('2000-01-01T12:00:00Z', Body.mars, 327.9632921, -1.0677752, null, null),
  ('2000-01-01T12:00:00Z', Body.mercury, 271.8892699, -0.994819, null, null),
  (
    '2000-01-01T12:00:00Z',
    Body.moon,
    223.323786,
    5.1707422,
    402416.7,
    0.2300638,
  ),
  ('2000-01-01T12:00:00Z', Body.neptune, 303.1930007, 0.2350026, null, null),
  ('2000-01-01T12:00:00Z', Body.saturn, 40.3956366, -2.4448533, null, null),
  ('2000-01-01T12:00:00Z', Body.sun, 280.3689092, 0.0002381, 147103719.1, null),
  ('2000-01-01T12:00:00Z', Body.uranus, 314.809168, -0.658324, null, null),
  ('2000-01-01T12:00:00Z', Body.venus, 241.5657794, 2.0663548, null, null),
  ('2025-01-13T22:27:00Z', Body.jupiter, 72.056931, -0.5570095, null, null),
  ('2025-01-13T22:27:00Z', Body.mars, 117.0803973, 4.2573983, null, null),
  ('2025-01-13T22:27:00Z', Body.mercury, 277.9930873, -0.5727494, null, null),
  (
    '2025-01-13T22:27:00Z',
    Body.moon,
    113.9966965,
    4.5953613,
    381415.9,
    0.9984009,
  ),
  ('2025-01-13T22:27:00Z', Body.neptune, 357.5209076, -1.2780993, null, null),
  ('2025-01-13T22:27:00Z', Body.saturn, 345.6080519, -1.9513883, null, null),
  ('2025-01-13T22:27:00Z', Body.sun, 293.9959098, 0.0001174, 147138405.6, null),
  ('2025-01-13T22:27:00Z', Body.uranus, 53.383584, -0.2484017, null, null),
  ('2025-01-13T22:27:00Z', Body.venus, 341.115455, -0.3036139, null, null),
  ('2050-12-31T00:00:00Z', Body.jupiter, 155.7218749, 1.0548095, null, null),
  ('2050-12-31T00:00:00Z', Body.mars, 4.8312355, -0.1243805, null, null),
  ('2050-12-31T00:00:00Z', Body.mercury, 257.0864121, 1.9504748, null, null),
  (
    '2050-12-31T00:00:00Z',
    Body.moon,
    132.4396777,
    -5.0649334,
    395663.1,
    0.9183076,
  ),
  ('2050-12-31T00:00:00Z', Body.neptune, 55.9160516, -1.748704, null, null),
  ('2050-12-31T00:00:00Z', Body.saturn, 307.6751253, -0.6418369, null, null),
  ('2050-12-31T00:00:00Z', Body.sun, 279.4785059, -9.6e-05, 147104841.4, null),
  ('2050-12-31T00:00:00Z', Body.uranus, 175.5458105, 0.7757923, null, null),
  ('2050-12-31T00:00:00Z', Body.venus, 232.6685688, 3.2170097, null, null),
];
