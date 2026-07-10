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

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();
  static const _secure = FlutterSecureStorage();
  static bool _secureAvailable = true;

  static String _apiKeyKey(String id) => 'api_key_$id';

  static Future<void> _writeSecure(String key, String value) async {
    if (!_secureAvailable) {
      await _writePrefsObfuscated(key, value);
      return;
    }
    try {
      await _secure.write(key: key, value: value);
    } catch (e) {
      debugPrint('Secure storage unavailable, using fallback: $e');
      _secureAvailable = false;
      await _writePrefsObfuscated(key, value);
    }
  }

  static Future<String?> _readSecure(String key) async {
    if (!_secureAvailable) {
      return _readPrefsObfuscated(key);
    }
    try {
      final val = await _secure.read(key: key);
      if (val != null) return val;
      return _readPrefsObfuscated(key);
    } catch (e) {
      debugPrint('Secure storage unavailable, using fallback: $e');
      _secureAvailable = false;
      return _readPrefsObfuscated(key);
    }
  }

  static Future<void> _deleteSecure(String key) async {
    if (!_secureAvailable) {
      await _deletePrefsKey(key);
      return;
    }
    try {
      await _secure.delete(key: key);
    } catch (_) {
      await _deletePrefsKey(key);
    }
  }

  static Future<void> _writePrefsObfuscated(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString('_obs_$key', _obfuscate(value));
  }

  static Future<String?> _readPrefsObfuscated(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString('_obs_$key');
    if (raw == null) return null;
    return _deobfuscate(raw);
  }

  static Future<void> _deletePrefsKey(String key) async {
    final prefs = await _prefs;
    await prefs.remove('_obs_$key');
  }

  static String _obfuscate(String input) {
    final bytes = utf8.encode(input);
    final key = _obfuscationKey();
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = bytes[i] ^ key[i % key.length];
    }
    return base64Encode(bytes);
  }

  static String _deobfuscate(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      final key = _obfuscationKey();
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = bytes[i] ^ key[i % key.length];
      }
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }

  static List<int> _obfuscationKey() {
    return [0x6B, 0x6F, 0x6B, 0x6F, 0x2D, 0x6B, 0x65, 0x79];
  }

  static Future<void> _cleanupOrphanedKeys(
      Set<String> currentIds) async {
    final prefs = await _prefs;
    final allKeys = prefs.getKeys();
    for (final k in allKeys) {
      if (k.startsWith('_obs_api_key_') || k.startsWith('api_key_')) {
        final id = k.startsWith('_obs_')
            ? k.substring(5).replaceFirst('api_key_', '')
            : k.replaceFirst('api_key_', '');
        if (!currentIds.contains(id)) {
          await prefs.remove(k);
          await _deleteSecure('api_key_$id');
        }
      }
    }

    try {
      final allSecure = await _secure.readAll();
      for (final k in allSecure.keys) {
        if (k.startsWith('api_key_') && !currentIds.contains(k.substring(8))) {
          await _secure.delete(key: k);
        }
      }
    } catch (_) {}
  }

  static Future<void> saveProviders(List<ProviderConfig> providers) async {
    final prefs = await _prefs;
    final data = providers.map((p) => p.toMap()).toList();
    await prefs.setString(_keyProviders, jsonEncode(data));

    for (final p in providers) {
      await _writeSecure(_apiKeyKey(p.id), p.apiKey);
    }

    await _cleanupOrphanedKeys(providers.map((p) => p.id).toSet());
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
