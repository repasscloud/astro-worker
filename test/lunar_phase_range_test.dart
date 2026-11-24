import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/infrastructure/meeus_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = MeeusEngine();

  for (final MapEntry(key: year, value: reference) in _phasesByYear.entries) {
    test('all primary moon phases in $year agree with USNO', () {
      final phases = engine
          .events(DateTime.utc(year), DateTime.utc(year + 1))
          .where((event) => event.category == EventCategory.moonPhase)
          .toList();

      expect(phases, hasLength(reference.length));
      for (final (index, (name, instant)) in reference.indexed) {
        final expected = DateTime.parse(instant);
        final event = phases[index];
        final reason = '$name at $instant';
        expect(event.name, name, reason: reason);
        expect(
          (event.instant.difference(expected)).abs(),
          lessThanOrEqualTo(const Duration(minutes: 2)),
          reason: reason,
        );
      }
    });
  }
}

// USNO primary phase tables use Universal Time at minute precision.
// https://aa.usno.navy.mil/api/moon/phases/year?year=2000
// https://aa.usno.navy.mil/api/moon/phases/year?year=2050
const _phasesByYear = <int, List<(String, String)>>{
  2000: [
    ('New Moon', '2000-01-06T18:14:00Z'),
    ('First Quarter', '2000-01-14T13:34:00Z'),
    ('Full Moon', '2000-01-21T04:40:00Z'),
    ('Last Quarter', '2000-01-28T07:57:00Z'),
    ('New Moon', '2000-02-05T13:03:00Z'),
    ('First Quarter', '2000-02-12T23:21:00Z'),
    ('Full Moon', '2000-02-19T16:27:00Z'),
    ('Last Quarter', '2000-02-27T03:54:00Z'),
    ('New Moon', '2000-03-06T05:17:00Z'),
    ('First Quarter', '2000-03-13T06:59:00Z'),
    ('Full Moon', '2000-03-20T04:44:00Z'),
    ('Last Quarter', '2000-03-28T00:21:00Z'),
    ('New Moon', '2000-04-04T18:12:00Z'),
    ('First Quarter', '2000-04-11T13:30:00Z'),
    ('Full Moon', '2000-04-18T17:42:00Z'),
    ('Last Quarter', '2000-04-26T19:30:00Z'),
    ('New Moon', '2000-05-04T04:12:00Z'),
    ('First Quarter', '2000-05-10T20:01:00Z'),
    ('Full Moon', '2000-05-18T07:34:00Z'),
    ('Last Quarter', '2000-05-26T11:55:00Z'),
    ('New Moon', '2000-06-02T12:14:00Z'),
    ('First Quarter', '2000-06-09T03:29:00Z'),
    ('Full Moon', '2000-06-16T22:27:00Z'),
    ('Last Quarter', '2000-06-25T01:00:00Z'),
    ('New Moon', '2000-07-01T19:20:00Z'),
    ('First Quarter', '2000-07-08T12:53:00Z'),
    ('Full Moon', '2000-07-16T13:55:00Z'),
    ('Last Quarter', '2000-07-24T11:02:00Z'),
    ('New Moon', '2000-07-31T02:25:00Z'),
    ('First Quarter', '2000-08-07T01:02:00Z'),
    ('Full Moon', '2000-08-15T05:13:00Z'),
    ('Last Quarter', '2000-08-22T18:51:00Z'),
    ('New Moon', '2000-08-29T10:19:00Z'),
    ('First Quarter', '2000-09-05T16:27:00Z'),
    ('Full Moon', '2000-09-13T19:37:00Z'),
    ('Last Quarter', '2000-09-21T01:28:00Z'),
    ('New Moon', '2000-09-27T19:53:00Z'),
    ('First Quarter', '2000-10-05T10:59:00Z'),
    ('Full Moon', '2000-10-13T08:53:00Z'),
    ('Last Quarter', '2000-10-20T07:59:00Z'),
    ('New Moon', '2000-10-27T07:58:00Z'),
    ('First Quarter', '2000-11-04T07:27:00Z'),
    ('Full Moon', '2000-11-11T21:15:00Z'),
    ('Last Quarter', '2000-11-18T15:24:00Z'),
    ('New Moon', '2000-11-25T23:11:00Z'),
    ('First Quarter', '2000-12-04T03:55:00Z'),
    ('Full Moon', '2000-12-11T09:03:00Z'),
    ('Last Quarter', '2000-12-18T00:41:00Z'),
    ('New Moon', '2000-12-25T17:22:00Z'),
  ],
  2050: [
    ('Full Moon', '2050-01-08T01:39:00Z'),
    ('Last Quarter', '2050-01-16T06:17:00Z'),
    ('New Moon', '2050-01-23T04:57:00Z'),
    ('First Quarter', '2050-01-29T20:48:00Z'),
    ('Full Moon', '2050-02-06T20:47:00Z'),
    ('Last Quarter', '2050-02-14T22:10:00Z'),
    ('New Moon', '2050-02-21T15:03:00Z'),
    ('First Quarter', '2050-02-28T11:29:00Z'),
    ('Full Moon', '2050-03-08T15:23:00Z'),
    ('Last Quarter', '2050-03-16T10:08:00Z'),
    ('New Moon', '2050-03-23T00:41:00Z'),
    ('First Quarter', '2050-03-30T04:17:00Z'),
    ('Full Moon', '2050-04-07T08:12:00Z'),
    ('Last Quarter', '2050-04-14T18:24:00Z'),
    ('New Moon', '2050-04-21T10:25:00Z'),
    ('First Quarter', '2050-04-28T22:08:00Z'),
    ('Full Moon', '2050-05-06T22:26:00Z'),
    ('Last Quarter', '2050-05-14T00:03:00Z'),
    ('New Moon', '2050-05-20T20:51:00Z'),
    ('First Quarter', '2050-05-28T16:04:00Z'),
    ('Full Moon', '2050-06-05T09:51:00Z'),
    ('Last Quarter', '2050-06-12T04:39:00Z'),
    ('New Moon', '2050-06-19T08:21:00Z'),
    ('First Quarter', '2050-06-27T09:17:00Z'),
    ('Full Moon', '2050-07-04T18:51:00Z'),
    ('Last Quarter', '2050-07-11T09:46:00Z'),
    ('New Moon', '2050-07-18T21:16:00Z'),
    ('First Quarter', '2050-07-27T01:05:00Z'),
    ('Full Moon', '2050-08-03T02:20:00Z'),
    ('Last Quarter', '2050-08-09T16:48:00Z'),
    ('New Moon', '2050-08-17T11:47:00Z'),
    ('First Quarter', '2050-08-25T14:56:00Z'),
    ('Full Moon', '2050-09-01T09:31:00Z'),
    ('Last Quarter', '2050-09-08T02:51:00Z'),
    ('New Moon', '2050-09-16T03:49:00Z'),
    ('First Quarter', '2050-09-24T02:34:00Z'),
    ('Full Moon', '2050-09-30T17:31:00Z'),
    ('Last Quarter', '2050-10-07T16:32:00Z'),
    ('New Moon', '2050-10-15T20:48:00Z'),
    ('First Quarter', '2050-10-23T12:10:00Z'),
    ('Full Moon', '2050-10-30T03:16:00Z'),
    ('Last Quarter', '2050-11-06T09:57:00Z'),
    ('New Moon', '2050-11-14T13:41:00Z'),
    ('First Quarter', '2050-11-21T20:25:00Z'),
    ('Full Moon', '2050-11-28T15:09:00Z'),
    ('Last Quarter', '2050-12-06T06:27:00Z'),
    ('New Moon', '2050-12-14T05:18:00Z'),
    ('First Quarter', '2050-12-21T04:15:00Z'),
    ('Full Moon', '2050-12-28T05:15:00Z'),
  ],
};
