import 'dart:convert';

import 'astronomy.dart';

String exportCalendar(
  Iterable<SkyEvent> events, {
  required DateTime createdAt,
}) {
  final unique = <String, SkyEvent>{};
  for (final event in events) {
    final name = Uri.encodeComponent(event.name);
    final id =
        '${event.category.name}-${event.body.name}-'
        '${event.instant.microsecondsSinceEpoch}-$name@astroworker';
    unique[id] = event;
  }
  final sorted = unique.entries.toList()
    ..sort((left, right) {
      final time = left.value.instant.compareTo(right.value.instant);
      return time == 0 ? left.key.compareTo(right.key) : time;
    });
  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Astro Worker//Astronomy Events//EN',
    'CALSCALE:GREGORIAN',
    for (final entry in sorted) ...[
      'BEGIN:VEVENT',
      'UID:${entry.key}',
      'DTSTAMP:${_utcStamp(createdAt)}',
      'DTSTART:${_utcStamp(entry.value.instant)}',
      'SUMMARY:${_escape(entry.value.name)}',
      'END:VEVENT',
    ],
    'END:VCALENDAR',
    '',
  ].map(_fold).join('\r\n');
}

String _utcStamp(DateTime instant) =>
    '${instant.toUtc().toIso8601String().split('.').first.replaceAll(RegExp('[-:]'), '')}Z';

String _escape(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll(RegExp(r'\r\n?|\n'), r'\n')
    .replaceAll(',', r'\,')
    .replaceAll(';', r'\;');

String _fold(String line) {
  final folded = StringBuffer();
  var bytes = 0;
  for (final rune in line.runes) {
    final character = String.fromCharCode(rune);
    final width = utf8.encode(character).length;
    if (bytes + width > 75) {
      folded.write('\r\n ');
      bytes = 1;
    }
    folded.write(character);
    bytes += width;
  }
  return folded.toString();
}
