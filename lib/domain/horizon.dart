class Observer {
  Observer({required this.latitude, required this.longitude}) {
    if (!latitude.isFinite ||
        latitude.abs() > 90 ||
        !longitude.isFinite ||
        longitude.abs() > 180) {
      throw const FormatException(
        'Latitude must be −90 to 90 and longitude −180 to 180.',
      );
    }
  }
  final double latitude;

  /// Degrees east of Greenwich.
  final double longitude;
}

enum HorizonKind {
  sunrise('Sunrise'),
  sunset('Sunset'),
  solarNoon('Solar noon'),
  moonrise('Moonrise'),
  moonset('Moonset'),
  civilDawn('Civil dawn'),
  civilDusk('Civil dusk'),
  nauticalDawn('Nautical dawn'),
  nauticalDusk('Nautical dusk'),
  astronomicalDawn('Astronomical dawn'),
  astronomicalDusk('Astronomical dusk');

  const HorizonKind(this.label);
  final String label;
}

typedef HorizonEvent = ({HorizonKind kind, DateTime instant});

class HorizonDay {
  const HorizonDay(this.events, this.daylight);
  final List<HorizonEvent> events;
  final Duration daylight;
}

abstract interface class HorizonEngine {
  HorizonDay horizon(DateTime from, DateTime until, Observer observer);
}

typedef HorizontalSamples = ({double sun, double moon, double moonThreshold});

/// Locates threshold crossings by sampling and bracket refinement. A short
/// fixed step keeps all twilight thresholds on the same astronomical samples.
HorizonDay solveHorizon(
  DateTime from,
  DateTime until,
  HorizontalSamples Function(DateTime) sample,
) {
  const thresholds = [
    (HorizonKind.sunrise, HorizonKind.sunset, -50 / 60),
    (HorizonKind.civilDawn, HorizonKind.civilDusk, -6.0),
    (HorizonKind.nauticalDawn, HorizonKind.nauticalDusk, -12.0),
    (HorizonKind.astronomicalDawn, HorizonKind.astronomicalDusk, -18.0),
    (HorizonKind.moonrise, HorizonKind.moonset, 0.0),
  ];
  const step = Duration(minutes: 5);
  final events = <HorizonEvent>[];
  double height(
    HorizontalSamples sample,
    HorizonKind rising,
    double threshold,
  ) => rising == HorizonKind.moonrise
      ? sample.moon - sample.moonThreshold
      : sample.sun - threshold;
  var previousInstant = from;
  var previous = sample(from);
  var highestInstant = from;
  var highestAltitude = previous.sun;
  DateTime? lightStarted = previous.sun >= -50 / 60 ? from : null;
  var daylight = Duration.zero;

  while (previousInstant.isBefore(until)) {
    final candidate = previousInstant.add(step);
    final instant = candidate.isAfter(until) ? until : candidate;
    final current = sample(instant);
    if (current.sun > highestAltitude) {
      highestAltitude = current.sun;
      highestInstant = instant;
    }
    for (final (rising, setting, threshold) in thresholds) {
      final wasAbove = height(previous, rising, threshold) >= 0;
      final isAbove = height(current, rising, threshold) >= 0;
      if (wasAbove == isAbove) continue;
      var low = previousInstant.millisecondsSinceEpoch;
      var high = instant.millisecondsSinceEpoch;
      while (high - low > 1000) {
        final middle = (low + high) ~/ 2;
        final altitude = height(
          sample(DateTime.fromMillisecondsSinceEpoch(middle, isUtc: true)),
          rising,
          threshold,
        );
        if ((altitude >= 0) == wasAbove) {
          low = middle;
        } else {
          high = middle;
        }
      }
      final event = DateTime.fromMillisecondsSinceEpoch(high, isUtc: true);
      if (event.isBefore(until)) {
        events.add((kind: isAbove ? rising : setting, instant: event));
      }
      if (rising == HorizonKind.sunrise) {
        if (isAbove) {
          lightStarted = event;
        } else {
          daylight += event.difference(lightStarted!);
          lightStarted = null;
        }
      }
    }
    previousInstant = instant;
    previous = current;
  }

  if (lightStarted != null) daylight += until.difference(lightStarted);
  if (highestInstant.isAfter(from) &&
      highestInstant.isBefore(until) &&
      highestAltitude > -90) {
    var low = highestInstant
        .subtract(step)
        .millisecondsSinceEpoch
        .clamp(from.millisecondsSinceEpoch, until.millisecondsSinceEpoch);
    var high = highestInstant
        .add(step)
        .millisecondsSinceEpoch
        .clamp(from.millisecondsSinceEpoch, until.millisecondsSinceEpoch);
    while (high - low > 1000) {
      final left = low + (high - low) ~/ 3;
      final right = high - (high - low) ~/ 3;
      if (sample(DateTime.fromMillisecondsSinceEpoch(left, isUtc: true)).sun <
          sample(DateTime.fromMillisecondsSinceEpoch(right, isUtc: true)).sun) {
        low = left;
      } else {
        high = right;
      }
    }
    final solarNoon = DateTime.fromMillisecondsSinceEpoch(
      (low + high) ~/ 2,
      isUtc: true,
    );
    events.add((kind: HorizonKind.solarNoon, instant: solarNoon));
  }
  events.sort((a, b) => a.instant.compareTo(b.instant));
  return HorizonDay(List.unmodifiable(events), daylight);
}
