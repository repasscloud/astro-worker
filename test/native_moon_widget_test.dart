import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:astro_worker/domain/zodiac.dart';
import 'package:astro_worker/platform/native_moon_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widget timeline changes the upcoming phase at the event instant', () {
    final engine = MeeusEngine();
    final now = DateTime.utc(2025, 1, 13, 22);
    final phases = engine.events(now, now.add(const Duration(days: 14)));
    final fullMoon = phases.firstWhere((event) => event.name == 'Full Moon');

    final rows = buildNativeMoonTimeline((
      engine: engine,
      now: now,
      zone: 'Australia/Adelaide',
      keepMasterNumbers: true,
      south: true,
      showSpiritual: false,
      zodiac: Zodiac.lahiri,
    ));

    expect(rows.first['nextPhase'], 'Full Moon');
    expect(rows.first['validUntil'], fullMoon.instant.toIso8601String());
    expect(rows[1]['generatedAt'], rows.first['validUntil']);
    expect(rows[1]['nextPhase'], 'Last Quarter');
    expect(rows.first['south'], true);
    expect(rows.first['zodiac'], 'lahiri');
    expect(rows.first['colourName'], 'Moonstone');
    expect(rows.every((row) => !row.containsKey('reflection')), true);
    expect(
      rows.last['validUntil'],
      now.add(const Duration(hours: 48)).toIso8601String(),
    );
  });
}
