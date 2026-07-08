import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semantic design tokens for RxMind themes.
/// All body-text foreground/background pairs are validated for WCAG 2.2 AA ≥ 4.5:1
/// in test/theme/contrast_ratio_test.dart.
class ThemeTokens {
  ThemeTokens._();

  static const String fontFamily = 'Poppins';
  static const double focusRingWidth = 3.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;

  // --- Light palette ---
  static const Color lightPrimary = Color(0xFF1565C0);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF00897B);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF212121);
  static const Color lightScaffold = Color(0xFFF4F6F8);
  static const Color lightError = Color(0xFFC62828);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightLink = Color(0xFF0D47A1);
  static const Color lightFocus = Color(0xFF1565C0);
  static const Color lightNavInactive = Color(0xFF616161);
  static const Color lightHint = Color(0xFF757575);

  // --- Dark palette ---
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkOnPrimary = Color(0xFF0D1B2A);
  static const Color darkSecondary = Color(0xFF4DB6AC);
  static const Color darkOnSecondary = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF232526);
  static const Color darkOnSurface = Color(0xFFF5F5F5);
  static const Color darkScaffold = Color(0xFF181A1B);
  static const Color darkError = Color(0xFFEF9A9A);
  static const Color darkOnError = Color(0xFF1B0000);
  static const Color darkLink = Color(0xFF90CAF9);
  static const Color darkFocus = Color(0xFF64B5F6);
  static const Color darkNavInactive = Color(0xFFB0BEC5);

  // --- High-contrast light ---
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

  // --- High-contrast dark ---
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
      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
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
        fontWeight: bold ? FontWeight.w700 : FontWeight.w700,
        fontSize: bold ? 36 : 32,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: titleWeight,
        fontSize: bold ? 24 : 20,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: labelWeight,
        fontSize: bold ? 18 : 16,
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
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: labelWeight,
        fontSize: bold ? 14 : 12,
      ),
    );
  }
}

/// Theme extension for link and focus-ring tokens not in ColorScheme.
@immutable
class RxMindThemeExtension extends ThemeExtension<RxMindThemeExtension> {
  const RxMindThemeExtension({
    required this.link,
    required this.focusRing,
    required this.navInactive,
    required this.focusRingWidth,
  });

  final Color link;
  final Color focusRing;
  final Color navInactive;
  final double focusRingWidth;

  @override
  RxMindThemeExtension copyWith({
    Color? link,
    Color? focusRing,
    Color? navInactive,
    double? focusRingWidth,
  }) {
    return RxMindThemeExtension(
      link: link ?? this.link,
      focusRing: focusRing ?? this.focusRing,
      navInactive: navInactive ?? this.navInactive,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
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
    );
  }

  static RxMindThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<RxMindThemeExtension>()!;
  }
}
