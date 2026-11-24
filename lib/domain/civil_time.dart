import 'package:timezone/timezone.dart' as tz;

DateTime inDisplayZone(DateTime instant, String zone) => switch (zone) {
  'device' => instant.toLocal(),
  'UTC' => instant.toUtc(),
  _ => tz.TZDateTime.from(instant, tz.getLocation(zone)),
};

/// Resolve a wall time to UTC. Returns null for skipped times and selects
/// the earlier instant when a wall time occurs twice during a rollback.
DateTime? resolveWallTime(DateTime wall, String zone) {
  final nominal = DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
  );
  final offsets = {
    for (final hours in [-30, 0, 30])
      inDisplayZone(nominal.add(Duration(hours: hours)), zone).timeZoneOffset,
  };
  for (final offset in offsets.toList()..sort((a, b) => b.compareTo(a))) {
    final candidate = nominal.subtract(offset);
    final converted = inDisplayZone(candidate, zone);
    if (converted.year == wall.year &&
        converted.month == wall.month &&
        converted.day == wall.day &&
        converted.hour == wall.hour &&
        converted.minute == wall.minute &&
        converted.second == wall.second) {
      return candidate;
    }
  }
  return null;
}
