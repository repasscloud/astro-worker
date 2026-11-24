import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/astrology.dart';
import 'package:astro_worker/domain/personal_charts.dart';
import 'package:astro_worker/domain/zodiac.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cross-chart conjunctions wrap correctly and retain chart roles', () {
    final aspects = compareLongitudes({Body.moon: 359}, {Body.sun: 1}, 4);
    expect(aspects.single.outer, Body.moon);
    expect(aspects.single.natal, Body.sun);
    expect(aspects.single.aspect, MajorAspect.conjunction);
    expect(aspects.single.orb, 2);
  });

  test(
    'composite midpoints follow the short arc and omit exact opposition',
    () {
      final result = compositeMidpoints(
        {Body.sun: 350, Body.moon: 45, Body.mars: 5},
        {Body.sun: 10, Body.moon: 225},
      );
      expect(result, {Body.sun: 0.0, Body.moon: null});
    },
  );

  test('solar return brackets the Sun returning to the selected longitude', () {
    final engine = MeeusEngine();
    final birth = DateTime.utc(2000, 3, 20, 12);
    for (final zodiac in Zodiac.values) {
      final longitude = chartLongitudes(
        engine.skyAt(birth),
        birth,
        zodiac,
      )[Body.sun]!;
      final hit = solarReturn(engine, longitude, birth, 2025, zodiac)!;
      expect(hit.month, 3);
      expect(hit.day, inInclusiveRange(18, 22));
      final longitudeAtReturn = chartLongitudes(
        engine.skyAt(hit),
        hit,
        zodiac,
      )[Body.sun]!;
      expect(
        signedAngle(longitudeAtReturn - longitude).abs(),
        lessThan(.00002),
      );
    }
  });
}
