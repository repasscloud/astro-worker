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
