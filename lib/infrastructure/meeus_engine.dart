import 'package:astronomia/apsis.dart' as apsis;
import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/eclipse.dart' as eclipse;
import 'package:astronomia/elliptic.dart' as elliptic;
import 'package:astronomia/julian.dart' as julian;
import 'package:astronomia/moonillum.dart' as illum;
import 'package:astronomia/moonphase.dart' as phases;
import 'package:astronomia/moonposition.dart' as moon;
import 'package:astronomia/nutation.dart' as nut;
import 'package:astronomia/planetposition.dart' as planets;
import 'package:astronomia/solar.dart' as solar;
import 'package:astronomia/sidereal.dart' as sidereal;
import 'package:astronomia/solstice.dart' as season;

import 'dart:math' as math;

import '../domain/astronomy.dart';
import '../domain/horizon.dart';
import '../domain/planetary_events.dart';

const _dayMs = 86400000;
const _epoch = 2440587.5;
const _auKm = 149597870.7;
const _degrees = 180 / math.pi;

/// UT is approximated by UTC. Delta T follows the NASA 2005–2050 polynomial
/// and its adjacent intervals, documented in the calculation notes.
class MeeusEngine
    implements AstronomyEngine, HorizonEngine, PlanetaryEventEngine {
  final _earth = planets.Planet(planets.planetEarth);
  final _planets = {
    Body.mercury: planets.Planet(planets.planetMercury),
    Body.venus: planets.Planet(planets.planetVenus),
    Body.mars: planets.Planet(planets.planetMars),
    Body.jupiter: planets.Planet(planets.planetJupiter),
    Body.saturn: planets.Planet(planets.planetSaturn),
    Body.uranus: planets.Planet(planets.planetUranus),
    Body.neptune: planets.Planet(planets.planetNeptune),
  };

  @override
  final start = DateTime.utc(2000);
  @override
  final end = DateTime.utc(2051);

  static double utcJulianDay(DateTime instant) =>
      _epoch + instant.millisecondsSinceEpoch / _dayMs;

  static double _deltaT(DateTime utc) {
    final year = utc.year + (utc.month - 0.5) / 12;
    final t = year - 2000;
    if (year < 2005) {
      return 63.86 +
          t *
              (0.3345 +
                  t *
                      (-0.060374 +
                          t *
                              (0.0017275 +
                                  t * (0.000651814 + t * 0.00002373599))));
    }
    if (year < 2050) return 62.92 + t * (0.32217 + t * 0.005589);
    final u = (year - 1820) / 100;
    return -20 + 32 * u * u - 0.5628 * (2150 - year);
  }

  DateTime _fromTerrestrial(double jde) {
    final provisional = DateTime.fromMillisecondsSinceEpoch(
      ((jde - _epoch) * _dayMs).round(),
      isUtc: true,
    );
    return provisional.subtract(
      Duration(milliseconds: (_deltaT(provisional) * 1000).round()),
    );
  }

  ({double lon, double lat, double ra, double dec, double? km}) _coordinates(
    Body body,
    double jde,
  ) {
    final nutation = nut.nutation(jde);
    final eps = nut.meanObliquity(jde) + nutation.dEps;
    if (body == Body.sun || body == Body.moon) {
      final t = julian.j2000Century(jde);
      final lunar = moon.position(jde);
      final lon = body == Body.sun
          ? solar.apparentLongitude(t)
          : lunar.lon + nutation.dPsi;
      final lat = body == Body.sun ? 0.0 : lunar.lat;
      final km = body == Body.sun ? solar.radius(t) * _auKm : lunar.delta;
      final eq = coord.eclToEq(lon, lat, math.sin(eps), math.cos(eps));
      return (lon: lon, lat: lat, ra: eq.ra, dec: eq.dec, km: km);
    }
    final eq = elliptic.position(_planets[body]!, _earth, jde);
    final ecliptic = coord.eqToEcl(eq.ra, eq.dec, math.sin(eps), math.cos(eps));
    return (
      lon: ecliptic.lon,
      lat: ecliptic.lat,
      ra: eq.ra,
      dec: eq.dec,
      km: null,
    );
  }

  double _longitudeSpeed(Body body, double jde) {
    final before = _coordinates(body, jde - 0.01);
    final after = _coordinates(body, jde + 0.01);
    return signedAngle((after.lon - before.lon) * _degrees) / 0.02;
  }

  @override
  List<PlanetaryEvent> planetaryEvents(
    Body body,
    DateTime from,
    DateTime until,
  ) {
    if (!_planets.containsKey(body)) return [];
    final lower = from.isBefore(start) ? start : from.toUtc();
    final upper = until.isAfter(end) ? end : until.toUtc();
    return solvePlanetaryEvents(lower, upper, (instant) {
      final jde = utcJulianDay(instant) + _deltaT(instant) / 86400;
      return (
        longitude: normalize(_coordinates(body, jde).lon * _degrees),
        speed: _longitudeSpeed(body, jde),
      );
    });
  }

  @override
  SkySnapshot skyAt(DateTime instant) {
    if (instant.isBefore(start) || !instant.isBefore(end)) {
      throw RangeError('Supported UTC dates are 2000–2050.');
    }
    final jde = utcJulianDay(instant) + _deltaT(instant.toUtc()) / 86400;
    final positions = <Body, CelestialPosition>{};
    for (final body in Body.values) {
      final at = _coordinates(body, jde);
      positions[body] = CelestialPosition(
        body: body,
        longitude: normalize(at.lon * _degrees),
        latitude: at.lat * _degrees,
        rightAscension: normalize(at.ra * _degrees),
        declination: at.dec * _degrees,
        speed: _longitudeSpeed(body, jde),
        distanceKm: at.km,
      );
    }
    final sun = positions[Body.sun]!;
    final lunar = positions[Body.moon]!;
    final angle = normalize(lunar.longitude - sun.longitude);
    final illumination = illum.illuminated(
      illum.phaseAngleEcl(
        lunar.longitude / _degrees,
        lunar.latitude / _degrees,
        lunar.distanceKm!,
        sun.longitude / _degrees,
        sun.distanceKm!,
      ),
    );
    final nearby = events(instant.subtract(const Duration(days: 31)), instant);
    final newMoons = nearby.where((event) => event.name == 'New Moon');
    final age = newMoons.isEmpty
        ? null
        : instant.difference(newMoons.last.instant).inSeconds / 86400;
    return SkySnapshot(Map.unmodifiable(positions), angle, illumination, age);
  }

  @override
  HorizonDay horizon(DateTime from, DateTime until, Observer observer) {
    if (from.isBefore(start) ||
        until.isAfter(end) ||
        !from.isBefore(until) ||
        until.difference(from) > const Duration(hours: 48)) {
      throw RangeError(
        'Observer calculation requires one civil day within the ephemeris range.',
      );
    }
    return solveHorizon(from.toUtc(), until.toUtc(), (instant) {
      final jd = utcJulianDay(instant);
      final jde = jd + _deltaT(instant) / 86400;
      final sun = _coordinates(Body.sun, jde);
      final lunar = _coordinates(Body.moon, jde);
      final greenwich = sidereal.apparent(jd) * 2 * math.pi / 86400;
      final latitude = observer.latitude / _degrees;
      final longitudeWest = -observer.longitude / _degrees;
      final sunAltitude = coord
          .eqToHz(sun.ra, sun.dec, latitude, longitudeWest, greenwich)
          .alt;
      final lunarAltitude = coord
          .eqToHz(lunar.ra, lunar.dec, latitude, longitudeWest, greenwich)
          .alt;
      // Approximate conventional upper-limb Moonrise with geocentric parallax.
      final lunarThreshold =
          0.7275 * moon.parallax(lunar.km!) * _degrees - 34 / 60;
      return (
        sun: sunAltitude * _degrees,
        moon: lunarAltitude * _degrees,
        moonThreshold: lunarThreshold,
      );
    });
  }

  @override
  List<SkyEvent> events(DateTime from, DateTime until) {
    final lower = from.isBefore(start) ? start : from.toUtc();
    final upper = until.isAfter(end) ? end : until.toUtc();
    if (!lower.isBefore(upper)) return [];
    final events = <SkyEvent>[];
    final seen = <(String, int)>{};
    void add(String title, double jde, EventCategory type, Body body) {
      final instant = _fromTerrestrial(jde);
      if (instant.isBefore(lower) || !instant.isBefore(upper)) return;
      if (seen.add((title, instant.millisecondsSinceEpoch))) {
        events.add(SkyEvent(title, instant, type, body));
      }
    }

    for (
      var date = lower.subtract(const Duration(days: 8));
      date.isBefore(upper.add(const Duration(days: 8)));
      date = date.add(const Duration(days: 7))
    ) {
      final yearStart = DateTime.utc(date.year);
      final yearEnd = DateTime.utc(date.year + 1);
      final decimal =
          date.year +
          date.difference(yearStart).inSeconds /
              yearEnd.difference(yearStart).inSeconds;
      add(
        'New Moon',
        phases.newMoon(decimal),
        EventCategory.moonPhase,
        Body.moon,
      );
      add(
        'First Quarter',
        phases.first(decimal),
        EventCategory.moonPhase,
        Body.moon,
      );
      add(
        'Full Moon',
        phases.full(decimal),
        EventCategory.moonPhase,
        Body.moon,
      );
      add(
        'Last Quarter',
        phases.last(decimal),
        EventCategory.moonPhase,
        Body.moon,
      );
      add(
        'Lunar perigee',
        apsis.perigee(decimal),
        EventCategory.apsis,
        Body.moon,
      );
      add(
        'Lunar apogee',
        apsis.apogee(decimal),
        EventCategory.apsis,
        Body.moon,
      );
      final solarEclipse = eclipse.solar(decimal);
      final lunarEclipse = eclipse.lunar(decimal);
      if (solarEclipse.type != eclipse.none) {
        add(
          'Solar eclipse',
          solarEclipse.jmax,
          EventCategory.eclipse,
          Body.sun,
        );
      }
      if (lunarEclipse.type != eclipse.none) {
        add(
          'Lunar eclipse',
          lunarEclipse.jmax,
          EventCategory.eclipse,
          Body.moon,
        );
      }
    }
    for (var year = lower.year; year <= upper.year; year++) {
      add('March equinox', season.march(year), EventCategory.season, Body.sun);
      add('June solstice', season.june(year), EventCategory.season, Body.sun);
      add(
        'September equinox',
        season.september(year),
        EventCategory.season,
        Body.sun,
      );
      add(
        'December solstice',
        season.december(year),
        EventCategory.season,
        Body.sun,
      );
    }
    return events..sort((a, b) => a.instant.compareTo(b.instant));
  }
}
