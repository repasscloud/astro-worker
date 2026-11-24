import 'package:astro_worker/domain/civil_time.dart';
import 'package:astro_worker/domain/numerology.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  test('Adelaide rejects skipped time and selects earlier repeated time', () {
    const zone = 'Australia/Adelaide';
    expect(resolveWallTime(DateTime.utc(2025, 10, 5, 2, 15), zone), isNull);
    expect(
      resolveWallTime(DateTime.utc(2025, 4, 6, 2, 15), zone),
      DateTime.utc(2025, 4, 5, 15, 45),
    );
    expect(
      inDisplayZone(DateTime.utc(2025, 7, 1), zone).timeZoneOffset,
      const Duration(hours: 9, minutes: 30),
    );
  });

  test('date-line midnight and leap day remain civil dates', () {
    expect(
      inDisplayZone(DateTime.utc(2024, 2, 28, 10), 'Pacific/Kiritimati').day,
      29,
    );
    expect(
      inDisplayZone(DateTime.utc(2024, 2, 29, 1), 'Pacific/Honolulu').day,
      28,
    );
  });

  test(
    'method retains configured master numbers and handles leap birthdays',
    () {
      const master = Numerology(keepMasterNumbers: true);
      const simple = Numerology(keepMasterNumbers: false);
      expect(master.universalDay(DateTime.utc(2025, 9, 2)), 11);
      expect(simple.universalDay(DateTime.utc(2025, 9, 2)), 2);
      expect(master.lifePath(DateTime.utc(2000, 2, 29)), 6);
      expect(
        master.personalYear(DateTime.utc(2025), DateTime.utc(2000, 2, 29)),
        22,
      );
    },
  );
}
