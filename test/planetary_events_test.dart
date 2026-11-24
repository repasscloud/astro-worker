import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/planetary_events.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2025, 1, 1);
  final end = start.add(const Duration(days: 1));
  double days(DateTime instant) =>
      instant.difference(start).inMilliseconds / 86400000;

  test('detects sign ingresses in both directions across zero longitude', () {
    for (final speed in [-2.0, 2.0]) {
      final event = solvePlanetaryEvents(start, end, (instant) {
        final longitude = normalize(speed * (days(instant) - .5));
        return (longitude: longitude, speed: speed);
      }).single;
      expect(event.kind, PlanetaryEventKind.ingress);
      expect(event.sign, speed < 0 ? 'Pisces' : 'Aries');
      expect(event.retrograde, speed < 0);
      expect(
        event.instant.difference(DateTime.utc(2025, 1, 1, 12)).abs(),
        lessThanOrEqualTo(const Duration(seconds: 1)),
      );
    }
  });

  test('detects two same-day ingresses on opposite sides of a station', () {
    final events = solvePlanetaryEvents(start, end, (instant) {
      final offset = days(instant) - .5;
      return (longitude: 31 - 8 * offset * offset, speed: -16 * offset);
    });
    expect(events.map((event) => event.sign), ['Taurus', null, 'Aries']);
    expect(events.map((event) => event.kind), [
      PlanetaryEventKind.ingress,
      PlanetaryEventKind.stationRetrograde,
      PlanetaryEventKind.ingress,
    ]);
    expect(
      events.map((event) => event.instant),
      orderedEquals(events.map((event) => event.instant).toList()..sort()),
    );
  });

  test(
    'resolves a complete Mercury retrograde interval with a reverse ingress',
    () {
      final engine = MeeusEngine();
      final events = engine.planetaryEvents(
        Body.mercury,
        DateTime.utc(2025, 3, 10),
        DateTime.utc(2025, 4, 12),
      );
      expect(events.map((event) => event.kind), [
        PlanetaryEventKind.stationRetrograde,
        PlanetaryEventKind.ingress,
        PlanetaryEventKind.stationDirect,
      ]);
      // JPL Horizons observer quantity 31, Earth centre, one-hour samples.
      final reference = [
        DateTime.utc(2025, 3, 15, 7),
        DateTime.utc(2025, 3, 30, 2, 18),
        DateTime.utc(2025, 4, 7, 11),
      ];
      for (var index = 0; index < reference.length; index++) {
        expect(
          events[index].instant.difference(reference[index]).abs(),
          lessThan(const Duration(minutes: 30)),
        );
      }
      expect(events[1].sign, 'Pisces');
      expect(events[1].retrograde, isTrue);
    },
  );
}
