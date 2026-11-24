import 'dart:convert';
import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import 'astronomy.dart';
import 'civil_time.dart';
import 'horizon.dart';
import 'zodiac.dart';

class BirthProfile {
  const BirthProfile({
    required this.id,
    required this.name,
    required this.day,
    required this.zone,
    this.minutes,
    this.location,
  });

  final String id;
  final String name;
  final DateTime day;
  final String zone;
  final int? minutes;
  final Observer? location;

  DateTime? get instant {
    final time = minutes;
    if (time == null) return null;
    return resolveWallTime(
      DateTime.utc(day.year, day.month, day.day, time ~/ 60, time % 60),
      zone,
    );
  }

  static bool validZone(String zone) =>
      zone == 'UTC' || tz.timeZoneDatabase.locations.containsKey(zone);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'day': day.toIso8601String().substring(0, 10),
    'zone': zone,
    'minutes': minutes,
    if (location case final site?) 'location': [site.latitude, site.longitude],
  };

  static List<BirthProfile>? decodeList(String? source) {
    if (source == null || source.length > 16384) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List || decoded.length > 24) return null;
      final profiles = <BirthProfile>[];
      final ids = <String>{};
      for (final row in decoded) {
        if (row
            case {
              'id': final String id,
              'name': final String name,
              'day': final String civil,
              'zone': final String zone,
              'minutes': final Object? rawMinutes,
            }
            when id.isNotEmpty &&
                id.length <= 32 &&
                ids.add(id) &&
                name.trim().isNotEmpty &&
                name.length <= 60 &&
                validZone(zone) &&
                (rawMinutes == null ||
                    rawMinutes is int &&
                        rawMinutes >= 0 &&
                        rawMinutes < 1440)) {
          final date = DateTime.tryParse(civil);
          if (date == null ||
              date.year < 1800 ||
              civil.length != 10 ||
              date.toIso8601String().substring(0, 10) != civil) {
            return null;
          }
          Observer? location;
          if (row['location'] != null) {
            if (row['location'] case [final num lat, final num lon]) {
              location = Observer(
                latitude: lat.toDouble(),
                longitude: lon.toDouble(),
              );
            } else {
              return null;
            }
          }
          final utcDay = DateTime.utc(date.year, date.month, date.day);
          profiles.add(
            BirthProfile(
              id: id,
              name: name,
              day: utcDay,
              zone: zone,
              minutes: rawMinutes as int?,
              location: location,
            ),
          );
        } else {
          return null;
        }
      }
      if (profiles.any(
        (profile) => profile.minutes != null && profile.instant == null,
      )) {
        return null;
      }
      return profiles;
    } on FormatException {
      return null;
    }
  }

  static String encodeList(List<BirthProfile> profiles) =>
      jsonEncode(profiles.map((profile) => profile.toJson()).toList());
}

abstract interface class BirthAngleEngine {
  double? ascendant(DateTime instant, Observer location);
}

enum HouseSystem {
  wholeSign('Whole sign'),
  equal('Equal');

  const HouseSystem(this.label);
  final String label;
}

/// Intersection of the apparent ecliptic with the eastern observer horizon.
/// Inputs are in radians except the geographical latitude in [Observer].
double? easternHorizonLongitude(
  double sidereal,
  double obliquity,
  Observer observer,
) {
  final latitude = observer.latitude * math.pi / 180;
  if ((observer.latitude.abs() - 90).abs() < 1e-9) return null;
  final a = math.cos(latitude) * math.cos(sidereal);
  final b =
      math.cos(latitude) * math.sin(sidereal) * math.cos(obliquity) +
      math.sin(latitude) * math.sin(obliquity);
  if (a.abs() < 1e-10 && b.abs() < 1e-10) return null;
  final candidate = math.atan2(-a, b);
  final east =
      -math.sin(sidereal) * math.cos(candidate) +
      math.cos(sidereal) * math.cos(obliquity) * math.sin(candidate);
  if (east.abs() < 1e-10) return null;
  return normalize((candidate + (east < 0 ? math.pi : 0)) * 180 / math.pi);
}

List<double> houseCusps(double ascendant, HouseSystem system) {
  final origin = switch (system) {
    HouseSystem.wholeSign => (normalize(ascendant) / 30).floor() * 30.0,
    HouseSystem.equal => ascendant,
  };
  return List.generate(12, (index) => normalize(origin + index * 30));
}

class NatalChart {
  const NatalChart({
    required this.signs,
    this.instant,
    this.sky,
    this.ascendant,
  });

  final Map<Body, String?> signs;
  final DateTime? instant;
  final SkySnapshot? sky;

  /// Longitude measured in the selected zodiac.
  final double? ascendant;
}

NatalChart? calculateNatalChart(
  AstronomyEngine engine,
  BirthProfile profile,
  Zodiac zodiac,
) {
  final instant = profile.instant;
  if (instant != null) {
    if (instant.isBefore(engine.start) || !instant.isBefore(engine.end)) {
      return null;
    }
    final sky = engine.skyAt(instant);
    final offset = zodiac.offset(instant);
    final location = profile.location;
    final tropical = location != null && engine is BirthAngleEngine
        ? (engine as BirthAngleEngine).ascendant(instant, location)
        : null;
    return NatalChart(
      instant: instant,
      sky: sky,
      signs: {
        for (final entry in sky.positions.entries)
          entry.key: entry.value.sign(offset),
      },
      ascendant: tropical == null ? null : normalize(tropical - offset),
    );
  }
  if (profile.minutes != null) return null;

  final first = civilDayStart(profile.day, profile.zone);
  final nextDay = civilDayStart(
    profile.day.add(const Duration(days: 1)),
    profile.zone,
  );
  if (first.isBefore(engine.start) ||
      nextDay.isAfter(engine.end) ||
      !first.isBefore(nextDay)) {
    return null;
  }
  final last = nextDay.subtract(const Duration(milliseconds: 1));
  final span = last.difference(first).inMicroseconds;
  final signSets = <Body, Set<String>>{};
  for (var index = 0; index <= 4; index++) {
    final sample = first.add(Duration(microseconds: span * index ~/ 4));
    final offset = zodiac.offset(sample);
    for (final position in engine.skyAt(sample).positions.values) {
      signSets.putIfAbsent(position.body, () => {}).add(position.sign(offset));
    }
  }
  return NatalChart(
    signs: {
      for (final entry in signSets.entries)
        entry.key: entry.value.length == 1 ? entry.value.single : null,
    },
  );
}
