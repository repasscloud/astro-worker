import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/reminders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

class _FixtureEngine implements AstronomyEngine {
  _FixtureEngine(this.fixture);

  final List<SkyEvent> fixture;

  @override
  DateTime get start => DateTime.utc(2000);

  @override
  DateTime get end => DateTime.utc(2051);

  @override
  List<SkyEvent> events(DateTime from, DateTime until) => fixture
      .where((e) => !e.instant.isBefore(from) && e.instant.isBefore(until))
      .toList();

  @override
  SkySnapshot skyAt(DateTime instant) => throw UnimplementedError();
}

void main() {
  setUpAll(tz.initializeTimeZones);
  final now = DateTime.utc(2025, 4, 5, 12);

  SkyEvent event(
    String title,
    DateTime instant, [
    EventCategory category = EventCategory.moonPhase,
  ]) => SkyEvent(title, instant, category, Body.moon);

  test(
    'quiet hours apply to the two occurrences of a repeated Adelaide time',
    () {
      final fixture = _FixtureEngine([
        event('First occurrence', DateTime.utc(2025, 4, 5, 15, 45)),
        event('Second occurrence', DateTime.utc(2025, 4, 5, 16, 45)),
        event('After quiet hours', DateTime.utc(2025, 4, 5, 18, 45)),
      ]);
      const settings = ReminderSettings(
        enabled: true,
        quietFrom: 22 * 60,
        quietUntil: 3 * 60,
      );
      final plan = planReminders(fixture, now, settings, 'Australia/Adelaide');
      expect(plan.map((item) => item.title), ['After quiet hours']);
      expect(planReminders(fixture, now, settings, 'Australia/Adelaide'), plan);
      expect(
        planReminders(
          fixture,
          now,
          settings,
          'Australia/Adelaide',
          applyQuietHours: false,
        ),
        hasLength(3),
      );
    },
  );

  test('advance notice keeps stable IDs, ignores other categories and caps the plan', () {
    final repeated = event('Same event', now.add(const Duration(days: 1)));
    final fixture = _FixtureEngine([
      event(
        'Ignored eclipse',
        now.add(const Duration(hours: 6)),
        EventCategory.eclipse,
      ),
      repeated,
      repeated,
      for (var day = 2; day <= 80; day++)
        event('Moon event', now.add(Duration(days: day))),
    ]);
    final onTime = planReminders(
      fixture,
      now,
      const ReminderSettings(enabled: true),
      'UTC',
    );
    final earlier = planReminders(
      fixture,
      now,
      const ReminderSettings(enabled: true, leadMinutes: 15),
      'UTC',
    );
    expect(onTime, hasLength(48));
    expect(earlier, hasLength(48));
    expect(earlier.map((item) => item.id), onTime.map((item) => item.id));
    expect(
      earlier.first.due,
      onTime.first.due.subtract(const Duration(minutes: 15)),
    );
    expect(
      planReminders(fixture, now, const ReminderSettings(), 'UTC'),
      isEmpty,
    );
  });

  test('invalid settings never enable reminders after decoding', () {
    const settings = ReminderSettings(
      enabled: true,
      quietFrom: 1320,
      quietUntil: 480,
    );
    final encoded = settings.encode();
    expect(
      ReminderSettings.decode(encoded)?.isQuiet(DateTime.utc(2025, 1, 1, 23)),
      isTrue,
    );
    expect(
      ReminderSettings.decode(encoded.replaceFirst('480', '1320')),
      isNull,
    );
    expect(
      ReminderSettings.decode(encoded.replaceFirst('moonPhase', 'unknown')),
      isNull,
    );
  });
}
