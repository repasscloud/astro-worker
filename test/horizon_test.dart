import 'package:astro_worker/domain/civil_time.dart';
import 'package:astro_worker/domain/horizon.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  final engine = MeeusEngine();
  setUpAll(tz.initializeTimeZones);

  test('Adelaide Sun and Moon events agree with the USNO sea-level table', () {
    // https://aa.usno.navy.mil/api/rstt/oneday?date=2025-07-01&coords=-34.9285,138.6007&tz=9.5
    const zone = 'Australia/Adelaide';
    final day = engine.horizon(
      civilDayStart(DateTime.utc(2025, 7, 1), zone),
      civilDayStart(DateTime.utc(2025, 7, 2), zone),
      Observer(latitude: -34.9285, longitude: 138.6007),
    );
    const references = {
      HorizonKind.civilDawn: (6, 56),
      HorizonKind.sunrise: (7, 24),
      HorizonKind.solarNoon: (12, 19),
      HorizonKind.sunset: (17, 15),
      HorizonKind.civilDusk: (17, 43),
      HorizonKind.moonrise: (11, 13),
      HorizonKind.moonset: (23, 18),
    };
    for (final MapEntry(key: kind, value: (hour, minute))
        in references.entries) {
      final expected = resolveWallTime(
        DateTime.utc(2025, 7, 1, hour, minute),
        zone,
      )!;
      final actual = day.events
          .singleWhere((event) => event.kind == kind)
          .instant;
      expect(
        actual.difference(expected).inSeconds.abs(),
        lessThanOrEqualTo(180),
        reason: kind.label,
      );
    }
  });

  test('polar day and night produce no fictional solar crossings', () {
    final observer = Observer(latitude: 80, longitude: 0);
    for (final (month, daylight) in [(6, 24), (12, 0)]) {
      final day = engine.horizon(
        DateTime.utc(2025, month, 21),
        DateTime.utc(2025, month, 22),
        observer,
      );
      expect(day.daylight, Duration(hours: daylight));
      expect(
        day.events.where(
          (event) => const {
            HorizonKind.sunrise,
            HorizonKind.sunset,
          }.contains(event.kind),
        ),
        isEmpty,
      );
    }
  });

  test(
    'rise and set agree with independent north, south and date-line cases',
    () {
      // Swiss Ephemeris 2.10.03 swe_rise_trans at sea level, with refraction,
      // 1013.25 hPa and 15 °C. Times rounded to the nearest minute.
      const cases = [
        (
          'Australia/Adelaide',
          -34.9285,
          138.6007,
          [(6, 16), (20, 32), (13, 24), (20, 24), (4, 53)],
        ),
        (
          'America/Los_Angeles',
          37.7749,
          -122.4194,
          [(7, 24), (17, 13), (12, 19), (17, 2), (7, 37)],
        ),
        (
          'Pacific/Apia',
          -13.8333,
          -171.75,
          [(6, 10), (19, 2), (12, 36), (18, 30), (4, 56)],
        ),
      ];
      const kinds = [
        HorizonKind.sunrise,
        HorizonKind.sunset,
        HorizonKind.solarNoon,
        HorizonKind.moonrise,
        HorizonKind.moonset,
      ];
      for (final (zone, latitude, longitude, times) in cases) {
        final horizon = engine.horizon(
          civilDayStart(DateTime.utc(2025, 1, 13), zone),
          civilDayStart(DateTime.utc(2025, 1, 14), zone),
          Observer(latitude: latitude, longitude: longitude),
        );
        for (var index = 0; index < kinds.length; index++) {
          final kind = kinds[index];
          final (hour, minute) = times[index];
          final expected = resolveWallTime(
            DateTime.utc(2025, 1, 13, hour, minute),
            zone,
          )!;
          final actual = horizon.events
              .singleWhere((event) => event.kind == kind)
              .instant;
          expect(
            actual.difference(expected).abs(),
            lessThanOrEqualTo(const Duration(minutes: 3)),
            reason: '$zone · ${kind.label}',
          );
        }
      }
    },
  );

  test('civil day bounds cover Australian DST and skip the Samoan date line change', () {
    const adelaide = 'Australia/Adelaide';
    expect(
      civilDayStart(
        DateTime.utc(2025, 10, 6),
        adelaide,
      ).difference(civilDayStart(DateTime.utc(2025, 10, 5), adelaide)),
      const Duration(hours: 23),
    );
    expect(
      civilDayStart(DateTime.utc(2011, 12, 30), 'Pacific/Apia'),
      civilDayStart(DateTime.utc(2011, 12, 31), 'Pacific/Apia'),
    );
  });
}
