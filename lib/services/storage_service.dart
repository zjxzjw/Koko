import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';

class StorageService {
  static const String _keyProviders = 'custom_providers';
  static const String _keySelected = 'selected_provider_id';

  /// Save the full list of provider configs to local storage.
  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final prefs = await SharedPreferences.getInstance();
    final data = providers.map((p) => p.toMap()).toList();
    await prefs.setString(_keyProviders, jsonEncode(data));
  }

  /// Load all provider configs. Returns default seed data when none exist.
  static Future<List<ProviderConfig>> loadProviders() async {
    final prefs = await SharedPreferences.getInstance();
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

  /// Persist the currently-selected provider ID.
  static Future<void> saveSelectedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelected, id);
  }

  /// Retrieve the last-saved provider ID, or null.
  static Future<String?> loadSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelected);
  }

  /// Seed data shown on first launch.
  static List<ProviderConfig> _defaultProviders() {
    return [
      ProviderConfig(
        id: '1',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com',
        apiKey: 'sk-***',
      ),
      ProviderConfig(
        id: '2',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com',
        apiKey: 'sk-***',
      ),
    ];
  }
}
