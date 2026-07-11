import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';

class StorageService {
  static const String _keyProviders = 'custom_providers';
  static const String _keySelected = 'selected_provider_id';
  static const String _keyLocale = 'app_locale';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyWindowX = 'window_x';
  static const String _keyWindowY = 'window_y';
  static const String _keyWindowW = 'window_w';
  static const String _keyWindowH = 'window_h';

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();
  static const _secure = FlutterSecureStorage();

  static String _apiKeyKey(String id) => 'api_key_$id';

  static Future<void> _writeSecure(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (e) {
      debugPrint('Secure storage error: $e');
      rethrow;
    }
  }

  static Future<String?> _readSecure(String key) async {
    try {
      return await _secure.read(key: key);
    } catch (e) {
      debugPrint('Secure storage read error: $e');
      return null;
    }
  }

  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final prefs = await _prefs;
    final data = providers.map((p) => p.toMap()).toList();
    await prefs.setString(_keyProviders, jsonEncode(data));

    for (final p in providers) {
      await _writeSecure(_apiKeyKey(p.id), p.apiKey);
    }
  }

  static Future<List<ProviderConfig>> loadProviders() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyProviders);
    if (raw == null || raw.isEmpty) return _defaultProviders();
    try {
      final List decoded = jsonDecode(raw);
      final list = decoded
          .map((item) => ProviderConfig.fromMap(item as Map<String, dynamic>))
          .toList();
      for (final p in list) {
        final key = await _readSecure(_apiKeyKey(p.id));
        if (key != null && key.isNotEmpty) {
          p.apiKey = key;
        }
      }
      return list;
    } catch (_) {
      return _defaultProviders();
    }
  }

  static Future<void> saveLastNotifyTime(String providerId) async {
    final prefs = await _prefs;
    await prefs.setInt('last_notify_$providerId',
        DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int> loadLastNotifyTime(String providerId) async {
    final prefs = await _prefs;
    return prefs.getInt('last_notify_$providerId') ?? 0;
  }

  static Future<void> saveSelectedId(String id) async {
    final prefs = await _prefs;
    await prefs.setString(_keySelected, id);
  }

  static Future<String?> loadSelectedId() async {
    final prefs = await _prefs;
    return prefs.getString(_keySelected);
  }

  static Future<void> saveLocale(String locale) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLocale, locale);
  }

  static Future<String> loadLocale() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLocale) ?? 'en';
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  static Future<String> loadThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> saveWindowPosition(double x, double y, double w, double h) async {
    final prefs = await _prefs;
    await prefs.setDouble(_keyWindowX, x);
    await prefs.setDouble(_keyWindowY, y);
    await prefs.setDouble(_keyWindowW, w);
    await prefs.setDouble(_keyWindowH, h);
  }

  static Future<double?> loadWindowX() async {
    final prefs = await _prefs;
    return prefs.getDouble(_keyWindowX);
  }

  static Future<double?> loadWindowY() async {
    final prefs = await _prefs;
    return prefs.getDouble(_keyWindowY);
  }

  static List<ProviderConfig> _defaultProviders() {
    return [
      ProviderConfig(
        id: ProviderConfig.generateId(),
        name: 'Add your provider',
        baseUrl: 'https://api.deepseek.com',
        apiKey: '',
        refreshIntervalMinutes: 10,
      ),
    ];
  }
}
