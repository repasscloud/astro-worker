import 'astronomy.dart';

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
        final futureDelta = signedAngle(
          delta + (second.speed - first.speed) / 24,
        );
        final futureOrb = (futureDelta.abs() - aspect.degrees).abs();
        aspects.add((
          first: first.body,
          second: second.body,
          aspect: aspect,
          orb: orb,
          motion: orb < 0.001
              ? 'Exact'
              : futureOrb < orb
              ? 'Applying'
              : 'Separating',
        ));
      }
    }
  }
  return aspects..sort((a, b) => a.orb.compareTo(b.orb));
}
