import 'dart:math' as math;

import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/birth_chart.dart';
import 'package:astro_worker/domain/horizon.dart';
import 'package:astro_worker/domain/zodiac.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);
  final engine = MeeusEngine();
  final day = DateTime.utc(2025, 1, 14);

  test('known Adelaide birth time resolves to the reference lunar instant', () {
    final profile = BirthProfile(
      id: 'fixture',
      name: 'Adelaide sample',
      day: day,
      zone: 'Australia/Adelaide',
      minutes: 8 * 60 + 57,
      location: Observer(latitude: -34.9285, longitude: 138.6007),
    );
    final chart = calculateNatalChart(engine, profile, Zodiac.tropical)!;
    expect(chart.instant, DateTime.utc(2025, 1, 13, 22, 27));
    expect(chart.signs[Body.moon], 'Cancer');
    expect(chart.ascendant, inInclusiveRange(0, 360));
    expect(
      BirthProfile.decodeList(BirthProfile.encodeList([profile]))!
          .single
          .instant,
      chart.instant,
    );
  });

  test(
    'unknown birth time never produces an instant, positions, or houses',
    () {
      final profile = BirthProfile(
        id: 'fixture',
        name: 'Unknown time',
        day: day,
        zone: 'Australia/Adelaide',
        location: Observer(latitude: -34.9285, longitude: 138.6007),
      );
      final chart = calculateNatalChart(engine, profile, Zodiac.tropical)!;
      expect(chart.instant, isNull);
      expect(chart.sky, isNull);
      expect(chart.ascendant, isNull);
      expect(chart.signs[Body.sun], 'Capricorn');
    },
  );

  test('matches independent tropical house fixtures in both hemispheres', () {
    // Swiss Ephemeris 2.10.03 swe_houses, UT JD 2460689.435416667.
    final instant = DateTime.utc(2025, 1, 13, 22, 27);
    const samples = [
      (-34.9285, 138.6007, 325.933680, [300, 330, 0]),
      (37.7749, -122.4194, 78.130233, [60, 90, 120]),
      (69.6492, 18.9553, 189.704273, [180, 210, 240]),
    ];
    for (final (latitude, longitude, expected, wholeSign) in samples) {
      final ascendant = engine.ascendant(
        instant,
        Observer(latitude: latitude, longitude: longitude),
      )!;
      expect(ascendant, closeTo(expected, .01), reason: 'latitude $latitude');
      expect(houseCusps(ascendant, HouseSystem.wholeSign).take(3), wholeSign);
      for (var index = 0; index < 12; index++) {
        expect(
          houseCusps(ascendant, HouseSystem.equal)[index],
          closeTo(normalize(expected + 30 * index), .01),
        );
      }
    }
  });

  test('equatorial horizon selects the eastern intersection and handles polar limits', () {
    final equator = Observer(latitude: 0, longitude: 0);
    expect(
      easternHorizonLongitude(0, 23.44 * math.pi / 180, equator),
      closeTo(90, .0001),
    );
    expect(
      easternHorizonLongitude(math.pi, 23.44 * math.pi / 180, equator),
      closeTo(270, .0001),
    );
    expect(
      easternHorizonLongitude(0, .4, Observer(latitude: 90, longitude: 0)),
      isNull,
    );
    expect(houseCusps(347, HouseSystem.wholeSign).take(2), [330, 0]);
    expect(houseCusps(347, HouseSystem.equal).take(2), [347, 17]);
  });

  test('skipped birth times and invalid profile dates cannot be restored', () {
    final invalid = BirthProfile(
      id: 'skip',
      name: 'Skipped time',
      day: DateTime.utc(2025, 10, 5),
      zone: 'Australia/Adelaide',
      minutes: 2 * 60 + 15,
    );
    expect(BirthProfile.decodeList(BirthProfile.encodeList([invalid])), isNull);
    expect(
      BirthProfile.decodeList(
        '[{"id":"bad","name":"Invalid","day":"2025-02-29","zone":"UTC","minutes":null}]',
      ),
      isNull,
    );
  });
}
