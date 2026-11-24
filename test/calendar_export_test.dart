import 'dart:convert';

import 'package:astro_worker/domain/astronomy.dart';
import 'package:astro_worker/domain/calendar_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports UTF-8 calendar text with stable IDs and UTC times', () {
    final title = 'Lune, équinoxe; \\\n${List.filled(50, '🌕').join()}';
    final event = SkyEvent(
      title,
      DateTime.parse('2025-01-02T10:43:12+10:30'),
      EventCategory.moonPhase,
      Body.moon,
    );
    final createdAt = DateTime.utc(2025, 1, 1);
    final data = exportCalendar([event, event], createdAt: createdAt);
    final lines = data.split('\r\n');
    final unfolded = data.replaceAll('\r\n ', '');
    expect(lines.every((line) => utf8.encode(line).length <= 75), isTrue);
    expect(lines.where((line) => line == 'BEGIN:VEVENT'), hasLength(1));
    expect(unfolded, contains('DTSTART:20250102T001312Z\r\n'));
    expect(unfolded, contains('DTSTAMP:20250101T000000Z\r\n'));
    expect(
      unfolded,
      contains(
        r'SUMMARY:Lune\, équinoxe\; \\\n' + List.filled(50, '🌕').join(),
      ),
    );
    final updated = exportCalendar(
      [event],
      createdAt: createdAt.add(const Duration(days: 1)),
    ).replaceAll('\r\n ', '');
    final uid = RegExp(r'UID:[^\r]+').firstMatch(unfolded)!.group(0);
    expect(updated, contains(uid));
  });
}
