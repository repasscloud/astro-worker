enum Body { sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune }

enum EventCategory { moonPhase, apsis, season, eclipse }

const zodiacSigns = [
  'Aries',
  'Taurus',
  'Gemini',
  'Cancer',
  'Leo',
  'Virgo',
  'Libra',
  'Scorpio',
  'Sagittarius',
  'Capricorn',
  'Aquarius',
  'Pisces',
];

const lunarPhases = [
  'New Moon',
  'Waxing Crescent',
  'First Quarter',
  'Waxing Gibbous',
  'Full Moon',
  'Waning Gibbous',
  'Last Quarter',
  'Waning Crescent',
];

double normalize(double degrees) => degrees % 360;
double signedAngle(double degrees) => normalize(degrees + 180) - 180;

class CelestialPosition {
  const CelestialPosition({
    required this.body,
    required this.longitude,
    required this.latitude,
    required this.rightAscension,
    required this.declination,
    required this.speed,
    this.distanceKm,
  });
  final Body body;
  final double longitude;
  final double latitude;
  final double rightAscension;
  final double declination;
  final double speed;
  final double? distanceKm;

  bool get retrograde => speed < 0;
  String get motion => speed.abs() < 0.001
      ? 'Near stationary'
      : retrograde
      ? 'Retrograde'
      : 'Direct';
  String sign([double offset = 0]) =>
      zodiacSigns[(normalize(longitude - offset) / 30).floor()];
  String zodiacPosition([double offset = 0]) {
    final arcseconds = (normalize(longitude - offset) * 3600).floor() % 108000;
    return "${arcseconds ~/ 3600}° ${arcseconds ~/ 60 % 60}′ ${arcseconds % 60}″";
  }
}

class SkySnapshot {
  const SkySnapshot(
    this.positions,
    this.elongation,
    this.illumination,
    this.lunarAgeDays,
  );
  final Map<Body, CelestialPosition> positions;
  final double elongation;
  final double illumination;
  final double? lunarAgeDays;
  String get phase => lunarPhases[(elongation / 45).round() % 8];
  bool get waxing => elongation < 180;
}

class SkyEvent {
  const SkyEvent(this.name, this.instant, this.category, this.body);
  final String name;
  final DateTime instant;
  final EventCategory category;
  final Body body;
}

abstract interface class AstronomyEngine {
  DateTime get start;
  DateTime get end;
  SkySnapshot skyAt(DateTime instant);
  List<SkyEvent> events(DateTime from, DateTime until);
}
