import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semantic design tokens for RxMind themes.
/// All body-text foreground/background pairs are validated for WCAG 2.2 AA ≥ 4.5:1
/// in test/theme/contrast_ratio_test.dart.
class ThemeTokens {
  ThemeTokens._();

  static const String fontFamily = 'PlusJakartaSans';
  static const double focusRingWidth = 3.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusPill = 999.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // --- Brand primitives ---
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandEmerald = Color(0xFF10B981);
  static const Color brandAmber = Color(0xFFFBBF24);
  static const Color brandViolet = Color(0xFF8B5CF6);
  static const Color brandRose = Color(0xFFF43F5E);
  static const Color brandCyan = Color(0xFF67E8F9);
  static const Color brandInk = Color(0xFF1E1E24);
  static const Color brandCanvas = Color(0xFFFFFFFF);
  static const Color brandSoft = Color(0xFFF9FAFB);
  static const Color brandMuted = Color(0xFFF3F4F6);
  static const Color brandBorder = Color(0xFFE2E8F0);
  static const Color brandFg = Color(0xFF111827);
  static const Color brandFgSecondary = Color(0xFF4B5563);
  static const Color brandFgMuted = Color(0xFF94A3B8);

  // Soft pastel wells (illustration / selection fills)
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color rose50 = Color(0xFFFFF1F2);

  // Dark-mode borders / muted wells
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkMuted = Color(0xFF1F2937);

  // --- Light palette ---
  static const Color lightPrimary = brandBlue;
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = brandEmerald;
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSurface = brandCanvas;
  static const Color lightOnSurface = brandFg;
  static const Color lightScaffold = brandSoft;
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightLink = Color(0xFF1D4ED8);
  static const Color lightFocus = brandBlue;
  static const Color lightNavInactive = Color(0xFF64748B);
  static const Color lightHint = Color(0xFF64748B);
  static const Color lightSuccess = brandEmerald;
  static const Color lightWarning = brandAmber;
  static const Color lightInfo = brandBlue;
  static const Color lightAiAccent = brandViolet;
  static const Color lightBorder = brandBorder;

  // --- Dark palette ---
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkOnPrimary = Color(0xFF0D1B2A);
  static const Color darkSecondary = Color(0xFF34D399);
  static const Color darkOnSecondary = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF232526);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkScaffold = Color(0xFF181A1B);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnError = Color(0xFF1B0000);
  static const Color darkLink = Color(0xFF90CAF9);
  static const Color darkFocus = Color(0xFF60A5FA);
  static const Color darkNavInactive = Color(0xFFB0BEC5);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF60A5FA);
  static const Color darkAiAccent = Color(0xFFA78BFA);

  // --- High-contrast light (unchanged philosophy) ---
  static const Color hcLightPrimary = Color(0xFF000000);
  static const Color hcLightOnPrimary = Color(0xFFFFFF00);
  static const Color hcLightSecondary = Color(0xFFFFFF00);
  static const Color hcLightOnSecondary = Color(0xFF000000);
  static const Color hcLightSurface = Color(0xFFFFFFFF);
  static const Color hcLightOnSurface = Color(0xFF000000);
  static const Color hcLightScaffold = Color(0xFFFFFFFF);
  static const Color hcLightError = Color(0xFFB71C1C);
  static const Color hcLightOnError = Color(0xFFFFFFFF);
  static const Color hcLightLink = Color(0xFF0000EE);
  static const Color hcLightFocus = Color(0xFF000000);

  // --- High-contrast dark (unchanged philosophy) ---
  static const Color hcDarkPrimary = Color(0xFFFFFF00);
  static const Color hcDarkOnPrimary = Color(0xFF000000);
  static const Color hcDarkSecondary = Color(0xFF00FFFF);
  static const Color hcDarkOnSecondary = Color(0xFF000000);
  static const Color hcDarkSurface = Color(0xFF000000);
  static const Color hcDarkOnSurface = Color(0xFFFFFFFF);
  static const Color hcDarkScaffold = Color(0xFF000000);
  static const Color hcDarkError = Color(0xFFFF6B6B);
  static const Color hcDarkOnError = Color(0xFF000000);
  static const Color hcDarkLink = Color(0xFF00FFFF);
  static const Color hcDarkFocus = Color(0xFFFFFF00);

  /// Relative luminance per WCAG 2.2.
  static double relativeLuminance(Color color) {
    double channel(int c) {
      final v = c / 255.0;
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(color.red);
    final g = channel(color.green);
    final b = channel(color.blue);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color a, Color b) {
    final l1 = relativeLuminance(a);
    final l2 = relativeLuminance(b);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static TextTheme textTheme({required bool bold, Brightness? brightness}) {
    final weight = bold ? FontWeight.w700 : FontWeight.w400;
    final titleWeight = bold ? FontWeight.w700 : FontWeight.w600;
    final labelWeight = bold ? FontWeight.w700 : FontWeight.w500;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: bold ? 36 : 32,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: titleWeight,
        fontSize: bold ? 24 : 22,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: titleWeight,
        fontSize: bold ? 20 : 18,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: labelWeight,
        fontSize: bold ? 16 : 14,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: bold ? 18 : 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: bold ? 16 : 14,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: bold ? 14 : 12,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: bold ? 16 : 14,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: labelWeight,
        fontSize: bold ? 14 : 12,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: labelWeight,
        fontSize: bold ? 12 : 11,
      ),
    );
  }
}

/// Theme extension for brand tokens not in ColorScheme.
@immutable
class RxMindThemeExtension extends ThemeExtension<RxMindThemeExtension> {
  const RxMindThemeExtension({
    required this.link,
    required this.focusRing,
    required this.navInactive,
    required this.focusRingWidth,
    required this.success,
    required this.warning,
    required this.aiAccent,
    required this.border,
    required this.softShadow,
  });

  final Color link;
  final Color focusRing;
  final Color navInactive;
  final double focusRingWidth;
  final Color success;
  final Color warning;
  final Color aiAccent;
  final Color border;
  final List<BoxShadow> softShadow;

  @override
  RxMindThemeExtension copyWith({
    Color? link,
    Color? focusRing,
    Color? navInactive,
    double? focusRingWidth,
    Color? success,
    Color? warning,
    Color? aiAccent,
    Color? border,
    List<BoxShadow>? softShadow,
  }) {
    return RxMindThemeExtension(
      link: link ?? this.link,
      focusRing: focusRing ?? this.focusRing,
      navInactive: navInactive ?? this.navInactive,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      aiAccent: aiAccent ?? this.aiAccent,
      border: border ?? this.border,
      softShadow: softShadow ?? this.softShadow,
    );
  }

  @override
  RxMindThemeExtension lerp(
    covariant ThemeExtension<RxMindThemeExtension>? other,
    double t,
  ) {
    if (other is! RxMindThemeExtension) return this;
    return RxMindThemeExtension(
      link: Color.lerp(link, other.link, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      focusRingWidth: focusRingWidth,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      aiAccent: Color.lerp(aiAccent, other.aiAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      softShadow: t < 0.5 ? softShadow : other.softShadow,
    );
  }

  static RxMindThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<RxMindThemeExtension>()!;
  }
}
