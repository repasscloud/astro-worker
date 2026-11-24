import 'dart:convert';

import 'package:astro_worker/infrastructure/preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  final today = DateTime.utc(2025, 1, 1);
  setUpAll(tz.initializeTimeZones);

  test(
    'migrates supported v1 values and purges malformed legacy entries',
    () async {
      SharedPreferences.setMockInitialValues({
        'astro.v1.birth': 20000229,
        'astro.v1.spiritual': 'true',
        'astro.v1.orb': 5,
        'astro.v1.observer': '-34.9285,138.6007',
        'unrelated': 'kept',
      });
      final preferences = await Preferences.open();
      expect(preferences.text('birth'), isNull);
      expect(preferences.flag('spiritual'), isNull);
      expect(preferences.decimal('orb'), 5);
      expect(preferences.text('observer'), '-34.9285,138.6007');

      final store = await SharedPreferences.getInstance();
      expect(
        store.getKeys().where((key) => key.startsWith('astro.v1.')),
        isEmpty,
      );
      expect(store.getString('unrelated'), 'kept');
      expect((await Preferences.open()).decimal('orb'), 5);
    },
  );

  test(
    'backups omit personal data unless requested and restore transactionally',
    () async {
      SharedPreferences.setMockInitialValues({
        'astro.v1.birth': '2000-02-29T00:00:00.000Z',
        'astro.v1.observer': '-34.9285,138.6007',
        'astro.v1.zone': 'Australia/Adelaide',
      });
      final preferences = await Preferences.open();
      final standard = preferences.exportBackup(includePersonal: false);
      final personal = preferences.exportBackup(includePersonal: true);
      expect(standard, contains('Australia/Adelaide'));
      expect(standard, isNot(contains('2000-02-29')));
      expect(standard, isNot(contains('138.6007')));
      expect(personal, contains('2000-02-29'));

      await Future.wait([
        preferences.writeText('zone', 'UTC'),
        preferences.writeFlag('masters', false),
      ]);
      expect(preferences.text('zone'), 'UTC');
      expect(preferences.flag('masters'), false);

      expect(await preferences.restoreBackup(standard, now: today), isTrue);
      expect(preferences.text('zone'), 'Australia/Adelaide');
      expect(preferences.text('birth'), contains('2000-02-29'));

      expect(await preferences.reset(), isTrue);
      final reloaded = await Preferences.open();
      expect(reloaded.text('birth'), isNull);
      expect(reloaded.text('observer'), isNull);
      expect(reloaded.text('zone'), isNull);
      expect(await reloaded.restoreBackup(personal, now: today), isTrue);
      expect(reloaded.text('birth'), contains('2000-02-29'));
    },
  );

  test(
    'rejects corrupt backups without changing the existing record',
    () async {
      SharedPreferences.setMockInitialValues({'astro.v1.zone': 'UTC'});
      final preferences = await Preferences.open();
      for (final invalid in [
        '{invalid json}',
        jsonEncode({'schema': 1, 'includesPersonal': false, 'values': {}}),
        jsonEncode({
          'schema': 2,
          'includesPersonal': false,
          'values': {'observer': '0,0'},
        }),
        jsonEncode({
          'schema': 2,
          'includesPersonal': true,
          'values': {'birth': '2001-02-29'},
        }),
        jsonEncode({
          'schema': 2,
          'includesPersonal': false,
          'values': {'zone': 'Missing/Zone'},
        }),
      ]) {
        expect(
          () => preferences.restoreBackup(invalid, now: today),
          throwsFormatException,
        );
        expect(preferences.text('zone'), 'UTC');
      }
      expect((await Preferences.open()).text('zone'), 'UTC');
    },
  );
}
