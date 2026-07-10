import 'package:flutter/material.dart';

class AppColors {
  static ThemeMode _mode = ThemeMode.light;

  static bool get isDark => _mode == ThemeMode.dark;

  static void setMode(ThemeMode mode) {
    _mode = mode;
  }

  static Color text(double opacity) =>
      (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);

  static Color surface(double opacity) =>
      (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);

  static Color border(double opacity) =>
      (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);

  static Color get primaryText => text(0.85);
  static Color get secondaryText => text(0.55);
  static Color get mutedText => text(0.45);
  static Color get dimText => text(0.35);
  static Color get faintText => text(0.25);
  static Color get subtleText => text(0.20);
  static Color get accentText => text(0.4);

  static Color get hoverBg => surface(0.04);
  static Color get cardBg => surface(0.03);
  static Color get overlayBg => surface(0.06);

  static Color get background => isDark ? const Color(0xFF1C1C1E) : Colors.white;
  static Color get dialogBg => isDark ? const Color(0xFF2C2C2E) : Colors.white;
  static Color get menuBg => isDark ? const Color(0xFF2C2C2E) : Colors.white;

  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartGreen = Color(0xFF10B981);
  static const Color statusGreen = Color(0xFF34C759);
}
