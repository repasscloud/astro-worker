import 'dart:convert';

import 'package:flutter/services.dart';

typedef DailyContent = ({
  String colour,
  int rgb,
  String theme,
  String affirmation,
  String prompt,
});

class EditorialContent {
  EditorialContent._(this._numbers, this._prompts);
  final Map<String, dynamic> _numbers;
  final List<String> _prompts;

  static Future<EditorialContent> load() async {
    final asset = await rootBundle.loadString('assets/content/en.v1.json');
    final json = jsonDecode(asset) as Map<String, dynamic>;
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported editorial content schema.');
    }
    return EditorialContent._(
      json['numbers'] as Map<String, dynamic>,
      List<String>.from(json['prompts'] as List),
    );
  }

  DailyContent forDay(int number, DateTime day) {
    final values = List<String>.from(_numbers['$number'] as List);
    final days =
        DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
        86400000;
    return (
      colour: values[0],
      rgb: int.parse(values[1], radix: 16),
      theme: values[2],
      affirmation: values[3],
      prompt: _prompts[days % _prompts.length],
    );
  }
}
