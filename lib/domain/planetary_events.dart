import 'astronomy.dart';

enum PlanetaryEventKind { ingress, stationDirect, stationRetrograde }

typedef PlanetaryMotion = ({double longitude, double speed});

typedef PlanetaryEvent = ({
  DateTime instant,
  PlanetaryEventKind kind,
  String? sign,
  bool retrograde,
});

abstract interface class PlanetaryEventEngine {
  List<PlanetaryEvent> planetaryEvents(
    Body body,
    DateTime from,
    DateTime until,
  );
}

/// Search a bounded interval of apparent longitude. Split a sampling interval
/// at each station before testing sign crossings so a reversal can cross the
/// same boundary in both directions.
List<PlanetaryEvent> solvePlanetaryEvents(
  DateTime from,
  DateTime until,
  PlanetaryMotion Function(DateTime) sample,
) {
  final lower = from.toUtc();
  final upper = until.toUtc();
  if (!upper.isAfter(lower)) return [];
  if (upper.difference(lower) > const Duration(days: 366)) {
    throw RangeError('Planetary event queries support up to 366 days.');
  }
  final events = <PlanetaryEvent>[];

  void scanIngress(
    DateTime left,
    DateTime right,
    double longitude,
    double endLongitude,
  ) {
    final movement = signedAngle(endLongitude - longitude);
    if (movement == 0) return;
    final forward = movement > 0;
    final sector = (longitude / 30).floor();
    final boundary = (sector + (forward ? 1 : 0)) * 30;
    final end = longitude + movement;
    if (forward ? end < boundary : end >= boundary) return;
    final crossing = _bisect(left, right, (instant) {
      final candidate =
          longitude + signedAngle(sample(instant).longitude - longitude);
      return forward ? candidate >= boundary : candidate < boundary;
    });
    if (!crossing.isBefore(upper)) return;
    events.add((
      instant: crossing,
      kind: PlanetaryEventKind.ingress,
      sign: zodiacSigns[(sector + (forward ? 1 : -1)) % 12],
      retrograde: !forward,
    ));
  }

  var left = lower;
  var before = sample(left);
  while (left.isBefore(upper)) {
    final step = left.add(const Duration(days: 1));
    final right = step.isBefore(upper) ? step : upper;
    final after = sample(right);
    final retrograde = after.speed < 0;
    if ((before.speed < 0) == retrograde) {
      scanIngress(left, right, before.longitude, after.longitude);
    } else {
      final station = _bisect(
        left,
        right,
        (instant) => (sample(instant).speed < 0) == retrograde,
      );
      final atStation = sample(station);
      scanIngress(left, station, before.longitude, atStation.longitude);
      if (station.isBefore(upper)) {
        events.add((
          instant: station,
          kind: retrograde
              ? PlanetaryEventKind.stationRetrograde
              : PlanetaryEventKind.stationDirect,
          sign: null,
          retrograde: retrograde,
        ));
      }
      scanIngress(station, right, atStation.longitude, after.longitude);
    }
    (left, before) = (right, after);
  }
  return events;
}

DateTime _bisect(DateTime left, DateTime right, bool Function(DateTime) after) {
  while (right.difference(left) > const Duration(seconds: 1)) {
    final mid = left.add(
      Duration(microseconds: right.difference(left).inMicroseconds ~/ 2),
    );
    if (after(mid)) {
      right = mid;
    } else {
      left = mid;
    }
  }
  return right;
}
