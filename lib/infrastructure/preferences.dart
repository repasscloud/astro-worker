import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Preferences(this._store);
  final SharedPreferences _store;

  static Future<Preferences> open() async =>
      Preferences(await SharedPreferences.getInstance());

  static const _prefix = 'astro.v1.';
  String? text(String key) => _store.getString('$_prefix$key');
  bool? flag(String key) => _store.getBool('$_prefix$key');
  double? decimal(String key) => _store.getDouble('$_prefix$key');
  Future<bool> writeText(String key, String value) =>
      _store.setString('$_prefix$key', value);
  Future<bool> writeFlag(String key, bool value) =>
      _store.setBool('$_prefix$key', value);
  Future<bool> writeDecimal(String key, double value) =>
      _store.setDouble('$_prefix$key', value);
  Future<bool> remove(String key) => _store.remove('$_prefix$key');
}
