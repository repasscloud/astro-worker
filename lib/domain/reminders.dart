import 'dart:convert';

import 'astronomy.dart';
import 'civil_time.dart';

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.categories = const {EventCategory.moonPhase},
    this.leadMinutes = 0,
    this.quietFrom,
    this.quietUntil,
  });

  final bool enabled;
  final Set<EventCategory> categories;
  final int leadMinutes;
  final int? quietFrom;
  final int? quietUntil;

  static const leadOptions = [0, 15, 60];

  static ReminderSettings? decode(String? stored) {
    if (stored == null || stored.length > 1024) return null;
    try {
      if (jsonDecode(stored)
          case {
            'enabled': final bool enabled,
            'categories': final List names,
            'leadMinutes': final int lead,
            'quietFrom': final Object? from,
            'quietUntil': final Object? until,
          }
          when leadOptions.contains(lead) && _validQuiet(from, until)) {
        final categories = names
            .map((name) => EventCategory.values.asNameMap()[name])
            .toSet();
        if (categories.isEmpty || categories.contains(null)) return null;
        return ReminderSettings(
          enabled: enabled,
          categories: categories.cast<EventCategory>(),
          leadMinutes: lead,
          quietFrom: from as int?,
          quietUntil: until as int?,
        );
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  String encode() => jsonEncode({
    'enabled': enabled,
    'categories': [for (final item in categories) item.name]..sort(),
    'leadMinutes': leadMinutes,
    'quietFrom': quietFrom,
    'quietUntil': quietUntil,
  });

  static bool _validQuiet(Object? from, Object? until) =>
      (from == null && until == null) ||
      (from is int &&
          until is int &&
          from >= 0 &&
          from < 1440 &&
          until >= 0 &&
          until < 1440 &&
          from != until);

  bool isQuiet(DateTime local) {
    final from = quietFrom;
    final until = quietUntil;
    if (from == null || until == null) return false;
    final minutes = local.hour * 60 + local.minute;
    return from < until
        ? minutes >= from && minutes < until
        : minutes >= from || minutes < until;
  }
}

typedef AstronomyReminder = ({
  String id,
  String title,
  DateTime event,
  DateTime due,
});

List<AstronomyReminder> planReminders(
  AstronomyEngine engine,
  DateTime now,
  ReminderSettings settings,
  String zone, {
  bool applyQuietHours = true,
}) {
  if (!settings.enabled) return [];
  final cutoff = now.add(const Duration(days: 90));
  final planned = <String, AstronomyReminder>{};
  for (final event in engine.events(now, cutoff)) {
    if (!settings.categories.contains(event.category)) continue;
    final due = event.instant.subtract(Duration(minutes: settings.leadMinutes));
    if (!due.isAfter(now)) continue;
    if (applyQuietHours && settings.isQuiet(inDisplayZone(due, zone))) continue;
    final id =
        '${event.category.name}/${event.body.name}/${event.name}/${event.instant.millisecondsSinceEpoch}';
    planned[id] = (id: id, title: event.name, event: event.instant, due: due);
    if (planned.length == 48) break;
  }
  return planned.values.toList();
}
