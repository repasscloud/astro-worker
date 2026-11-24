import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/astrology.dart';
import 'package:astro_worker/domain/zodiac.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2025, 1, 1);
  final end = start.add(const Duration(hours: 6));
  double hours(DateTime instant) =>
      instant.difference(start).inMilliseconds / 3600000;

  test('brackets a conjunction across zero and rejects the opposite wrap', () {
    final hits = exactAspectHits(
      start,
      end,
      MajorAspect.conjunction,
      (instant) => normalize(357.5 + hours(instant)),
    );
    expect(hits, hasLength(1));
    expect(
      hits.single.difference(DateTime.utc(2025, 1, 1, 2, 30)).abs(),
      lessThanOrEqualTo(const Duration(seconds: 1)),
    );
    expect(
      exactAspectHits(
        start,
        end,
        MajorAspect.conjunction,
        (instant) => 177 + hours(instant),
      ),
      isEmpty,
    );
  });

  test(
    'finds either branch of a sextile and includes an exact sample once',
    () {
      for (final direction in [-1, 1]) {
        expect(
          exactAspectHits(
            start,
            end,
            MajorAspect.sextile,
            (instant) => direction * (57 + hours(instant)),
          ),
          [DateTime.utc(2025, 1, 1, 3)],
        );
      }
    },
  );

  test('uses instantaneous approach rate just before and after a crossing', () {
    SkySnapshot sky(double longitude) => SkySnapshot(
      {
        Body.sun: _position(Body.sun, 0, 1),
        Body.moon: _position(Body.moon, longitude, 15),
      },
      longitude,
      0,
      null,
    );
    expect(activeAspects(sky(359.9), 1).single.motion, 'Applying');
    expect(activeAspects(sky(.1), 1).single.motion, 'Separating');
    expect(activeAspects(sky(0), 1).single.motion, 'Exact');
  });

  test('uses the published mean ayanamsa anchor and wraps shifted signs', () {
    final j2000 = DateTime.utc(2000, 1, 1, 12);
    expect(Zodiac.lahiri.offset(j2000), closeTo(23.8570923, .0000001));
    expect(
      Zodiac.faganBradley.offset(DateTime.utc(1950)),
      closeTo(24.0420444, .0000001),
    );
    expect(Zodiac.lahiri.offset(DateTime.utc(2050)), greaterThan(24.55));
    final body = _position(Body.sun, 15, 1);
    expect(body.sign(Zodiac.tropical.offset(j2000)), 'Aries');
    expect(body.sign(Zodiac.lahiri.offset(j2000)), 'Pisces');
  });
}

CelestialPosition _position(Body body, double longitude, double speed) =>
    CelestialPosition(
      body: body,
      longitude: longitude,
      latitude: 0,
      rightAscension: 0,
      declination: 0,
      speed: speed,
      distanceKm: null,
    );
