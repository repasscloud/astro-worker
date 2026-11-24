import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = MeeusEngine();

  test('2025 season timings agree with the US Naval Observatory', () {
    final published = {
      'March equinox': DateTime.utc(2025, 3, 20, 9, 1),
      'June solstice': DateTime.utc(2025, 6, 21, 2, 42),
      'September equinox': DateTime.utc(2025, 9, 22, 18, 19),
      'December solstice': DateTime.utc(2025, 12, 21, 15, 3),
    };
    final events = engine
        .events(DateTime.utc(2025), DateTime.utc(2026))
        .where((event) => event.category == EventCategory.season);
    expect(events.map((event) => event.name), orderedEquals(published.keys));
    for (final event in events) {
      expect(
        event.instant.difference(published[event.name]!).abs(),
        lessThan(const Duration(minutes: 3)),
        reason: event.name,
      );
    }
  });

  test('global greatest eclipse timings agree with NASA GSFC samples', () {
    final published = {
      'Solar eclipse': DateTime.utc(2024, 4, 8, 18, 17, 18),
      'Lunar eclipse': DateTime.utc(2025, 3, 14, 6, 58, 42),
    };
    for (final entry in published.entries) {
      final events = engine.events(
        entry.value.subtract(const Duration(hours: 12)),
        entry.value.add(const Duration(hours: 12)),
      );
      final eclipse = events.singleWhere(
        (event) =>
            event.category == EventCategory.eclipse && event.name == entry.key,
      );
      expect(
        eclipse.instant.difference(entry.value).abs(),
        lessThan(const Duration(minutes: 3)),
        reason: eclipse.name,
      );
    }
  });
}
