import 'package:shared_preferences/shared_preferences.dart';

/// Tiny wrapper around SharedPreferences for persistent storage.
class LocalStorage {
  LocalStorage._();
  static late SharedPreferences _prefs;

  static const String kAuthToken = 'auth_token';
  static const String kUsername = 'username';
  static const String kRememberMe = 'remember_me';
  static const String kAppType = 'app_type'; // 'customer' | 'admin'
  static const String kFontScale = 'font_scale';
  static const String kThemeMode = 'theme_mode';
  static const String kAdminPeriodPrefix =
      'admin_period_'; // + userId, persists the dashboard period per user

  static void init(SharedPreferences prefs) => _prefs = prefs;

  static String? getString(String key) => _prefs.getString(key);
  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  static bool getBool(String key, {bool def = false}) =>
      _prefs.getBool(key) ?? def;
  static Future<bool> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  static Future<bool> remove(String key) => _prefs.remove(key);
  static Future<bool> clear() => _prefs.clear();
}
