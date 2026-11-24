import 'astronomy.dart';
import 'event_refinement.dart';

enum MajorAspect {
  conjunction(0),
  sextile(60),
  square(90),
  trine(120),
  opposition(180);

  const MajorAspect(this.degrees);
  final double degrees;
}

typedef ActiveAspect = ({
  Body first,
  Body second,
  MajorAspect aspect,
  double orb,
  String motion,
});

List<ActiveAspect> activeAspects(SkySnapshot sky, double maxOrb) {
  final positions = sky.positions.values.toList();
  final aspects = <ActiveAspect>[];
  for (var i = 0; i < positions.length; i++) {
    for (final second in positions.skip(i + 1)) {
      final first = positions[i];
      final delta = signedAngle(second.longitude - first.longitude);
      for (final aspect in MajorAspect.values) {
        final orb = (delta.abs() - aspect.degrees).abs();
        if (orb > maxOrb) continue;
        final separationRate =
            (second.speed - first.speed) * (delta < 0 ? -1 : 1);
        final motion = (delta.abs() - aspect.degrees) * separationRate;
        aspects.add((
          first: first.body,
          second: second.body,
          aspect: aspect,
          orb: orb,
          motion: orb < 0.001
              ? 'Exact'
              : motion < 0
              ? 'Applying'
              : motion > 0
              ? 'Separating'
              : 'Stationary',
        ));
      }
    }
  }
  return aspects..sort((a, b) => a.orb.compareTo(b.orb));
}

/// Find exact hits for one aspect and pair using a bounded UTC bracket search.
/// Sample the signed phase of the pair, then test the appropriate branches of
/// the aspect. The opposite side of a signed-angle wrapping is not a crossing.
List<DateTime> exactAspectHits(
  DateTime from,
  DateTime until,
  MajorAspect aspect,
  double Function(DateTime) relativeLongitude,
) {
  final upper = until.toUtc();
  var left = from.toUtc();
  if (!left.isBefore(upper)) return [];
  if (upper.difference(left) > const Duration(days: 14)) {
    throw RangeError('Exact aspect queries support up to 14 days.');
  }
  const step = Duration(hours: 1);
  final targets = [
    aspect.degrees,
    if (aspect != MajorAspect.conjunction && aspect != MajorAspect.opposition)
      -aspect.degrees,
  ];
  final hits = <DateTime>{};
  var before = relativeLongitude(left);
  while (left.isBefore(upper)) {
    final next = left.add(step);
    final right = next.isBefore(upper) ? next : upper;
    final after = relativeLongitude(right);
    for (final target in targets) {
      final a = signedAngle(before - target);
      final b = signedAngle(after - target);
      if (a == 0) hits.add(left);
      if (b == 0 || (a.sign == b.sign) || (a - b).abs() >= 180) continue;
      if (a == 0) continue;
      final hit = refineEvent(
        left,
        right,
        (instant) => signedAngle(relativeLongitude(instant) - target) * b >= 0,
      );
      if (hit.isBefore(upper)) hits.add(hit);
    }
    (left, before) = (right, after);
  }
  return hits.toList()..sort();
}

abstract interface class RelativeLongitudeEngine {
  double relativeLongitude(Body first, Body second, DateTime instant);
}
