import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color dimText;
  final Color faintText;
  final Color subtleText;
  final Color accentText;
  final Color hoverBg;
  final Color cardBg;
  final Color overlayBg;
  final Color background;
  final Color dialogBg;
  final Color menuBg;

  static const chartBlue = Color(0xFF3B82F6);
  static const chartGreen = Color(0xFF10B981);
  static const statusGreen = Color(0xFF34C759);

  const AppColors({
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.dimText,
    required this.faintText,
    required this.subtleText,
    required this.accentText,
    required this.hoverBg,
    required this.cardBg,
    required this.overlayBg,
    required this.background,
    required this.dialogBg,
    required this.menuBg,
  });

  static const light = AppColors(
    primaryText: Color(0xD9000000),
    secondaryText: Color(0x8C000000),
    mutedText: Color(0x73000000),
    dimText: Color(0x59000000),
    faintText: Color(0x40000000),
    subtleText: Color(0x33000000),
    accentText: Color(0x66000000),
    hoverBg: Color(0x0A000000),
    cardBg: Color(0x08000000),
    overlayBg: Color(0x0F000000),
    background: Colors.white,
    dialogBg: Colors.white,
    menuBg: Colors.white,
  );

  static const dark = AppColors(
    primaryText: Color(0xD9FFFFFF),
    secondaryText: Color(0x8CFFFFFF),
    mutedText: Color(0x73FFFFFF),
    dimText: Color(0x59FFFFFF),
    faintText: Color(0x40FFFFFF),
    subtleText: Color(0x33FFFFFF),
    accentText: Color(0x66FFFFFF),
    hoverBg: Color(0x0AFFFFFF),
    cardBg: Color(0x08FFFFFF),
    overlayBg: Color(0x0FFFFFFF),
    background: Color(0xFF1C1C1E),
    dialogBg: Color(0xFF2C2C2E),
    menuBg: Color(0xFF2C2C2E),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? dimText,
    Color? faintText,
    Color? subtleText,
    Color? accentText,
    Color? hoverBg,
    Color? cardBg,
    Color? overlayBg,
    Color? background,
    Color? dialogBg,
    Color? menuBg,
  }) {
    return AppColors(
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      dimText: dimText ?? this.dimText,
      faintText: faintText ?? this.faintText,
      subtleText: subtleText ?? this.subtleText,
      accentText: accentText ?? this.accentText,
      hoverBg: hoverBg ?? this.hoverBg,
      cardBg: cardBg ?? this.cardBg,
      overlayBg: overlayBg ?? this.overlayBg,
      background: background ?? this.background,
      dialogBg: dialogBg ?? this.dialogBg,
      menuBg: menuBg ?? this.menuBg,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      dimText: Color.lerp(dimText, other.dimText, t)!,
      faintText: Color.lerp(faintText, other.faintText, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      overlayBg: Color.lerp(overlayBg, other.overlayBg, t)!,
      background: Color.lerp(background, other.background, t)!,
      dialogBg: Color.lerp(dialogBg, other.dialogBg, t)!,
      menuBg: Color.lerp(menuBg, other.menuBg, t)!,
    );
  }
}
