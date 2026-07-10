import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';

class StorageService {
  static const String _keyProviders = 'custom_providers';
  static const String _keySelected = 'selected_provider_id';
  static const String _keyLocale = 'app_locale';
  static const String _keyThemeMode = 'theme_mode';

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final prefs = await _prefs;
    final data = providers.map((p) => p.toMap()).toList();
    await prefs.setString(_keyProviders, jsonEncode(data));
  }

  static Future<List<ProviderConfig>> loadProviders() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyProviders);
    if (raw == null || raw.isEmpty) return _defaultProviders();
    try {
      final List decoded = jsonDecode(raw);
      return decoded
          .map((item) => ProviderConfig.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultProviders();
    }
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
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'sk-***',
        refreshIntervalMinutes: 10,
      ),
      ProviderConfig(
        id: ProviderConfig.generateId(),
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-***',
        refreshIntervalMinutes: 10,
      ),
    ];
  }
}
