import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/horizon.dart';
import '../domain/zodiac.dart';

class Preferences {
  Preferences._(this._store, this._values);

  final SharedPreferences _store;
  Map<String, Object> _values;
  Future<void> _pending = Future.value();

  static const _legacyPrefix = 'astro.v1.';
  static const _key = 'astro.v2.preferences';
  static const _textKeys = {
    'theme',
    'zone',
    'zodiac',
    'birth',
    'observer',
    'reminders',
  };
  static const _flagKeys = {'spiritual', 'masters', 'south'};
  static const _personalKeys = {'birth', 'observer'};
  static const _deviceKeys = {'reminders'};
  static const _keys = {..._textKeys, ..._flagKeys, 'orb'};

  static Future<Preferences> open() async {
    final store = await SharedPreferences.getInstance();
    if (store.containsKey(_key)) {
      final stored = store.get(_key);
      final values = stored is String
          ? _readStored(stored)
          : <String, Object>{};
      final preferences = Preferences._(store, values);
      await preferences._purgeLegacy();
      return preferences;
    }

    final legacy = {
      for (final key in _keys)
        key: ?_convert(key, store.get('$_legacyPrefix$key')),
    };
    final preferences = Preferences._(store, legacy);
    if (_keys.any((key) => store.containsKey('$_legacyPrefix$key'))) {
      if (await preferences._save(legacy)) await preferences._purgeLegacy();
    }
    return preferences;
  }

  String? text(String key) => _values[key] as String?;
  bool? flag(String key) => _values[key] as bool?;
  double? decimal(String key) => _values[key] as double?;

  Future<bool> writeText(String key, String value) => _write(key, value);
  Future<bool> writeFlag(String key, bool value) => _write(key, value);
  Future<bool> writeDecimal(String key, double value) => _write(key, value);

  Future<bool> _write(String key, Object value) {
    final checked = _convert(key, value);
    if (checked == null) return Future.value(false);
    return _queue(() => _save({..._values, key: checked}));
  }

  Future<bool> remove(String key) => _queue(() async {
    if (!await _store.remove('$_legacyPrefix$key')) return false;
    return _save({..._values}..remove(key));
  });

  String exportBackup({required bool includePersonal}) =>
      const JsonEncoder.withIndent('  ').convert({
        'schema': 2,
        'includesPersonal': includePersonal,
        'values': {
          for (final entry in _values.entries)
            if (!_deviceKeys.contains(entry.key) &&
                (includePersonal || !_personalKeys.contains(entry.key)))
              entry.key: entry.value,
        },
      });

  Future<bool> restoreBackup(String backup, {required DateTime now}) {
    if (backup.length > 8192) {
      throw const FormatException('Backup is too large.');
    }
    final decoded = jsonDecode(backup);
    if (decoded case {
      'schema': 2,
      'includesPersonal': final bool includesPersonal,
      'values': final Map entries,
    }) {
      final incoming = <String, Object>{};
      for (final entry in entries.entries) {
        final key = entry.key;
        if (key is! String ||
            _deviceKeys.contains(key) ||
            (!includesPersonal && _personalKeys.contains(key))) {
          throw const FormatException('Unexpected personal data or setting.');
        }
        final value = _convert(key, entry.value);
        if (value == null || !_validImport(key, value, now)) {
          throw FormatException('Invalid backup setting: $key.');
        }
        incoming[key] = value;
      }
      return _queue(() async {
        if (!await _purgeLegacy()) return false;
        return _save({
          for (final key in _deviceKeys) key: ?_values[key],
          if (!includesPersonal)
            for (final key in _personalKeys) key: ?_values[key],
          ...incoming,
        });
      });
    }
    throw const FormatException('Unrecognised settings backup.');
  }

  Future<bool> reset() => _queue(() async {
    if (!await _purgeLegacy()) return false;
    return _save({});
  });

  Future<bool> _save(Map<String, Object> values) async {
    final saved = await _store.setString(
      _key,
      jsonEncode({'schema': 2, 'values': values}),
    );
    if (saved) {
      _values = values;
    } else {
      await _store.reload();
    }
    return saved;
  }

  Future<bool> _purgeLegacy() async {
    var removed = true;
    for (final key in _keys) {
      final legacy = '$_legacyPrefix$key';
      if (_store.containsKey(legacy) && !await _store.remove(legacy)) {
        removed = false;
      }
    }
    return removed;
  }

  Future<bool> _queue(Future<bool> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static Map<String, Object> _readStored(String stored) {
    try {
      if (jsonDecode(stored) case {'schema': 2, 'values': final Map values}) {
        return {for (final key in _keys) key: ?_convert(key, values[key])};
      }
    } on FormatException {
      // Recover defaults without restoring older personal records.
    }
    return {};
  }

  static Object? _convert(String key, Object? value) => switch (value) {
    final String text when _textKeys.contains(key) => text,
    final bool flag when _flagKeys.contains(key) => flag,
    final num number when key == 'orb' && number.isFinite => number.toDouble(),
    _ => null,
  };

  static bool _validImport(String key, Object value, DateTime now) =>
      switch (key) {
        'theme' => const {'light', 'dark', 'system'}.contains(value),
        'zodiac' => Zodiac.values.asNameMap().containsKey(value),
        'zone' =>
          const {'device', 'UTC'}.contains(value) ||
              tz.timeZoneDatabase.locations.containsKey(value),
        'orb' => (value as double) >= 1 && value <= 10,
        'birth' => parseBirthDate(value as String, now) != null,
        'observer' => parseObserver(value as String) != null,
        _ => true,
      };

  static DateTime? parseBirthDate(String? value, DateTime now) {
    if (value == null || value.length < 10) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.year < 1800) return null;
    final date = DateTime.utc(parsed.year, parsed.month, parsed.day);
    if (date.toIso8601String().substring(0, 10) != value.substring(0, 10)) {
      return null;
    }
    final today = DateTime.utc(now.year, now.month, now.day);
    return date.isAfter(today) ? null : date;
  }

  static Observer? parseObserver(String? value) {
    final coordinates = value?.split(',');
    if (coordinates == null || coordinates.length != 2) return null;
    try {
      return Observer(
        latitude: double.parse(coordinates.first),
        longitude: double.parse(coordinates.last),
      );
    } on FormatException {
      return null;
    }
  }
}
