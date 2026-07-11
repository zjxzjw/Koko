import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../services/storage_service.dart';

class ThemeModeSettingNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return StorageService.loadThemeMode();
  }

  Future<void> setThemeMode(String mode) async {
    await StorageService.saveThemeMode(mode);
    state = AsyncData(mode);
  }

  ThemeMode parseThemeMode() => switch (state.asData?.value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final themeModeSettingProvider =
    AsyncNotifierProvider<ThemeModeSettingNotifier, String>(
  ThemeModeSettingNotifier.new,
);

class LocaleSettingNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final code = await StorageService.loadLocale();
    AppLocalizations.setLocale(code);
    return code;
  }

  Future<void> setLocale(String code) async {
    await StorageService.saveLocale(code);
    AppLocalizations.setLocale(code);
    state = AsyncData(code);
  }
}

final localeSettingProvider =
    AsyncNotifierProvider<LocaleSettingNotifier, String>(
  LocaleSettingNotifier.new,
);
