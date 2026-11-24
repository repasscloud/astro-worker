import 'package:astro_worker/infrastructure/preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'invalid saved types fall back and an older integer orb still loads',
    () async {
      SharedPreferences.setMockInitialValues({
        'astro.v1.birth': 20000229,
        'astro.v1.spiritual': 'true',
        'astro.v1.orb': 5,
        'astro.v1.invalid': double.nan,
      });
      final preferences = await Preferences.open();
      expect(preferences.text('birth'), isNull);
      expect(preferences.flag('spiritual'), isNull);
      expect(preferences.decimal('orb'), 5);
      expect(preferences.decimal('invalid'), isNull);

      expect(await preferences.remove('birth'), isTrue);
      expect(
        (await SharedPreferences.getInstance()).containsKey('astro.v1.birth'),
        isFalse,
      );
    },
  );
}
