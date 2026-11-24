import 'package:astro_worker/infrastructure/content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnglishOnlyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('/es.')) throw FlutterError('Missing Spanish fixture.');
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Spanish regional locales select a deterministic Spanish editorial pack',
    () async {
      final first = await EditorialContent.load(
        locale: const Locale('es', 'MX'),
      );
      final second = await EditorialContent.load(
        locale: const Locale('es', 'ES'),
      );
      final day = DateTime.utc(2025, 2, 2);
      final editorial = first.forDay(11, day);

      expect(first.locale, 'es');
      expect(editorial.colour, 'Plata');
      expect(editorial.intention, isNot(editorial.theme));
      expect(editorial.interpretation, isNotEmpty);
      expect(editorial, second.forDay(11, day.add(const Duration(hours: 22))));
      expect(
        editorial.prompt,
        isNot(first.forDay(11, day.add(const Duration(days: 1))).prompt),
      );
    },
  );

  test(
    'unsupported locale and missing asset fall back to English offline',
    () async {
      final unsupported = await EditorialContent.load(
        locale: const Locale('fr', 'CA'),
      );
      final missing = await EditorialContent.load(
        locale: const Locale('es', 'MX'),
        bundle: _EnglishOnlyBundle(),
      );
      expect(unsupported.locale, 'en');
      expect(missing.locale, 'en');
      expect(
        unsupported.forDay(22, DateTime.utc(2025)),
        missing.forDay(22, DateTime.utc(2025)),
      );
    },
  );
}
