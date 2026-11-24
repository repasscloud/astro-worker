import 'astronomy.dart';
import 'astrology.dart';
import 'event_refinement.dart';
import 'zodiac.dart';

typedef ComparisonAspect = ({
  Body outer,
  Body natal,
  MajorAspect aspect,
  double orb,
});

Map<Body, double> chartLongitudes(
  SkySnapshot sky,
  DateTime instant,
  Zodiac zodiac,
) {
  final offset = zodiac.offset(instant);
  return {
    for (final body in sky.positions.values)
      body.body: normalize(body.longitude - offset),
  };
}

List<ComparisonAspect> compareLongitudes(
  Map<Body, double> outer,
  Map<Body, double> natal,
  double maxOrb,
) {
  final results = <ComparisonAspect>[];
  for (final first in outer.entries) {
    for (final second in natal.entries) {
      final separation = signedAngle(first.value - second.value).abs();
      for (final aspect in MajorAspect.values) {
        final orb = (separation - aspect.degrees).abs();
        if (orb <= maxOrb) {
          results.add((
            outer: first.key,
            natal: second.key,
            aspect: aspect,
            orb: orb,
          ));
        }
      }
    }
  }
  return results..sort((left, right) => left.orb.compareTo(right.orb));
}

Map<Body, double?> compositeMidpoints(
  Map<Body, double> first,
  Map<Body, double> second,
) => {
  for (final body in first.keys)
    if (second[body] case final longitude?)
      body: _shortMidpoint(first[body]!, longitude),
};

double? _shortMidpoint(double a, double b) {
  final separation = signedAngle(b - a);
  if ((separation.abs() - 180).abs() < 1e-9) return null;
  return normalize(a + separation / 2);
}

DateTime? solarReturn(
  AstronomyEngine engine,
  double natalLongitude,
  DateTime birthday,
  int year,
  Zodiac zodiac,
) {
  final anniversary = DateTime.utc(year, birthday.month, birthday.day);
  final from = anniversary.subtract(const Duration(days: 14));
  final until = anniversary.add(const Duration(days: 14));
  final finalSample = engine.end.subtract(const Duration(milliseconds: 1));
  final last = until.isBefore(engine.end) ? until : finalSample;
  DateTime left = from.isBefore(engine.start) ? engine.start : from;
  if (!left.isBefore(last)) return null;
  double phase(DateTime instant) => signedAngle(
    engine.skyAt(instant).positions[Body.sun]!.longitude -
        zodiac.offset(instant) -
        natalLongitude,
  );
  var before = phase(left);
  while (left.isBefore(last)) {
    if (before == 0) return left;
    final next = left.add(const Duration(days: 1));
    final right = next.isBefore(last) ? next : last;
    final after = phase(right);
    if (before < 0 && after >= 0 && after - before < 180) {
      return refineEvent(left, right, (instant) => phase(instant) >= 0);
    }
    (left, before) = (right, after);
  }
  return null;
}
