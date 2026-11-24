import 'dart:math' as math;

import 'astronomy.dart';
import 'astrology.dart';
import 'horizon.dart';
import 'planetary_events.dart';
import 'zodiac.dart';

abstract interface class LunarOrientationEngine {
  double? lunarRotation(DateTime instant, SkySnapshot sky, Observer observer);
}

/// Position angle in radians, measured eastward from celestial north.
double brightLimbPositionAngle(CelestialPosition sun, CelestialPosition moon) {
  const radians = math.pi / 180;
  final deltaRa = (sun.rightAscension - moon.rightAscension) * radians;
  final solarDec = sun.declination * radians;
  final lunarDec = moon.declination * radians;
  return math.atan2(
    math.cos(solarDec) * math.sin(deltaRa),
    math.sin(solarDec) * math.cos(lunarDec) -
        math.cos(solarDec) * math.sin(lunarDec) * math.cos(deltaRa),
  );
}

/// Rotation from a right-lit disc in a horizon-aligned screen coordinate system.
double? lunarRotationForObserver(
  CelestialPosition sun,
  CelestialPosition moon,
  double localSiderealRadians,
  Observer observer,
) {
  const radians = math.pi / 180;
  final side = localSiderealRadians - moon.rightAscension * radians;
  final dec = moon.declination * radians;
  final latitude = observer.latitude * radians;
  final east = math.cos(latitude) * math.sin(side);
  final north =
      math.sin(latitude) * math.cos(dec) -
      math.cos(latitude) * math.sin(dec) * math.cos(side);
  if (east.abs() < 1e-10 && north.abs() < 1e-10) return null;
  final zenithAngle = math.atan2(east, north);
  return -math.pi / 2 - (brightLimbPositionAngle(sun, moon) - zenithAngle);
}

enum VoidOfCourseRule {
  classical('Classical bodies'),
  extended('Include Uranus and Neptune');

  const VoidOfCourseRule(this.label);
  final String label;
}

typedef VoidOfCourseWindow = ({DateTime start, DateTime end, String? sign});

VoidOfCourseWindow? lunarVoidOfCourse({
  required DateTime instant,
  required Zodiac zodiac,
  required VoidOfCourseRule rule,
  required PlanetaryEventEngine ingresses,
  required RelativeLongitudeEngine positions,
}) {
  const span = Duration(days: 4);
  final crossings = ingresses
      .planetaryEvents(
        Body.moon,
        instant.subtract(span),
        instant.add(span),
        zodiac: zodiac,
      )
      .where((event) => event.kind == PlanetaryEventKind.ingress);
  final previous = crossings
      .where((event) => !event.instant.isAfter(instant))
      .lastOrNull;
  final next = crossings
      .where((event) => event.instant.isAfter(instant))
      .firstOrNull;
  if (previous == null || next == null) return null;

  var lastAspect = previous.instant;
  for (final body in Body.values.where(
    (body) =>
        body != Body.moon &&
        (rule == VoidOfCourseRule.extended || body.index <= Body.saturn.index),
  )) {
    final samples = <DateTime, double>{};
    for (final aspect in MajorAspect.values) {
      final times = exactAspectHits(
        previous.instant,
        next.instant,
        aspect,
        (time) => samples.putIfAbsent(
          time,
          () => positions.relativeLongitude(Body.moon, body, time),
        ),
      );
      if (times.lastOrNull case final hit? when hit.isAfter(lastAspect)) {
        lastAspect = hit;
      }
    }
  }
  return (start: lastAspect, end: next.instant, sign: previous.sign);
}
