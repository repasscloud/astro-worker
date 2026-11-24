import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef DailyContent = ({
  String colour,
  int rgb,
  String theme,
  String affirmation,
  String intention,
  String interpretation,
  String prompt,
});

typedef _NumberEditorial = ({
  String colour,
  int rgb,
  String theme,
  String affirmation,
  String intention,
  String interpretation,
});

class EditorialContent {
  EditorialContent._(this.locale, this._numbers, this._prompts);
  final String locale;
  final Map<int, _NumberEditorial> _numbers;
  final List<String> _prompts;

  static const _languages = {'en', 'es'};
  static const _numbersInUse = {1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 22, 33};

  static Future<EditorialContent> load({
    Locale? locale,
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final language = locale?.languageCode;
    if (language != null && language != 'en' && _languages.contains(language)) {
      try {
        return await _load(assets, language);
      } on FormatException {
        // A packaged translation can fall back to the English edition.
      } on FlutterError {
        // A missing translation uses the English edition.
      }
    }
    return _load(assets, 'en');
  }

  static Future<EditorialContent> _load(
    AssetBundle bundle,
    String language,
  ) async {
    final asset = await bundle.loadString('assets/content/$language.v2.json');
    final json = jsonDecode(asset);
    if (json
        case {
          'schema': 2,
          'locale': final String locale,
          'numbers': final Map data,
          'prompts': final List prompts,
        }
        when locale == language) {
      final numbers = <int, _NumberEditorial>{};
      for (final number in _numbersInUse) {
        if (data['$number']
            case {
              'colour': final String colour,
              'rgb': final String hex,
              'theme': final String theme,
              'affirmation': final String affirmation,
              'intention': final String intention,
              'interpretation': final String interpretation,
            }
            when RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
          numbers[number] = (
            colour: colour,
            rgb: int.parse(hex, radix: 16),
            theme: theme,
            affirmation: affirmation,
            intention: intention,
            interpretation: interpretation,
          );
        } else {
          throw FormatException('Invalid editorial entry for $number.');
        }
      }
      if (prompts.isNotEmpty &&
          prompts.every(
            (prompt) => prompt is String && prompt.trim().isNotEmpty,
          )) {
        return EditorialContent._(locale, numbers, prompts.cast<String>());
      }
    }
    throw FormatException('Invalid editorial content for $language.');
  }

  DailyContent forDay(int number, DateTime day) {
    final entry = _numbers[number]!;
    final days =
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        86400000;
    return (
      colour: entry.colour,
      rgb: entry.rgb,
      theme: entry.theme,
      affirmation: entry.affirmation,
      intention: entry.intention,
      interpretation: entry.interpretation,
      prompt: _prompts[days % _prompts.length],
    );
  }
}
