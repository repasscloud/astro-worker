import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Preferences(this._store);
  final SharedPreferences _store;

  static Future<Preferences> open() async =>
      Preferences(await SharedPreferences.getInstance());

  static const _prefix = 'astro.v1.';
  String? text(String key) => switch (_store.get('$_prefix$key')) {
    final String value => value,
    _ => null,
  };
  bool? flag(String key) => switch (_store.get('$_prefix$key')) {
    final bool value => value,
    _ => null,
  };
  double? decimal(String key) => switch (_store.get('$_prefix$key')) {
    final num value when value.isFinite => value.toDouble(),
    _ => null,
  };
  Future<bool> writeText(String key, String value) =>
      _store.setString('$_prefix$key', value);
  Future<bool> writeFlag(String key, bool value) =>
      _store.setBool('$_prefix$key', value);
  Future<bool> writeDecimal(String key, double value) =>
      _store.setDouble('$_prefix$key', value);
  Future<bool> remove(String key) => _store.remove('$_prefix$key');
}
