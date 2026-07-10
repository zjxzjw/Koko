import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';

class StorageService {
  static const String _keyProviders = 'custom_providers';
  static const String _keySelected = 'selected_provider_id';
  static const String _keyLocale = 'app_locale';
  static const String _keyThemeMode = 'theme_mode';

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();
  static const _secure = FlutterSecureStorage();

  static String _apiKeyKey(String id) => 'api_key_$id';

  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final prefs = await _prefs;
    final data = providers.map((p) => p.toMap()).toList();
    await prefs.setString(_keyProviders, jsonEncode(data));

    for (final p in providers) {
      await _secure.write(key: _apiKeyKey(p.id), value: p.apiKey);
    }

    final currentIds = providers.map((p) => p.id).toSet();
    final allKeys = await _secure.readAll();
    for (final key in allKeys.keys) {
      if (key.startsWith('api_key_') && !currentIds.contains(key.substring(8))) {
        await _secure.delete(key: key);
      }
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
        final key = await _secure.read(key: _apiKeyKey(p.id));
        if (key != null) {
          _setApiKey(p, key);
        }
      }
      return list;
    } catch (_) {
      return _defaultProviders();
    }
  }

  static void _setApiKey(ProviderConfig p, String key) {
    p.apiKey = key;
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
