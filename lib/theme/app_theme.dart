import 'package:flutter/material.dart';
import 'theme_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primary: ThemeTokens.lightPrimary,
        onPrimary: ThemeTokens.lightOnPrimary,
        secondary: ThemeTokens.lightSecondary,
        onSecondary: ThemeTokens.lightOnSecondary,
        surface: ThemeTokens.lightSurface,
        onSurface: ThemeTokens.lightOnSurface,
        scaffold: ThemeTokens.lightScaffold,
        error: ThemeTokens.lightError,
        onError: ThemeTokens.lightOnError,
        link: ThemeTokens.lightLink,
        focus: ThemeTokens.lightFocus,
        navInactive: ThemeTokens.lightNavInactive,
        hint: ThemeTokens.lightHint,
        bold: false,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: ThemeTokens.darkPrimary,
        onPrimary: ThemeTokens.darkOnPrimary,
        secondary: ThemeTokens.darkSecondary,
        onSecondary: ThemeTokens.darkOnSecondary,
        surface: ThemeTokens.darkSurface,
        onSurface: ThemeTokens.darkOnSurface,
        scaffold: ThemeTokens.darkScaffold,
        error: ThemeTokens.darkError,
        onError: ThemeTokens.darkOnError,
        link: ThemeTokens.darkLink,
        focus: ThemeTokens.darkFocus,
        navInactive: ThemeTokens.darkNavInactive,
        hint: ThemeTokens.darkNavInactive,
        bold: false,
      );

  static ThemeData get highContrastTheme => _buildTheme(
        brightness: Brightness.light,
        primary: ThemeTokens.hcLightPrimary,
        onPrimary: ThemeTokens.hcLightOnPrimary,
        secondary: ThemeTokens.hcLightSecondary,
        onSecondary: ThemeTokens.hcLightOnSecondary,
        surface: ThemeTokens.hcLightSurface,
        onSurface: ThemeTokens.hcLightOnSurface,
        scaffold: ThemeTokens.hcLightScaffold,
        error: ThemeTokens.hcLightError,
        onError: ThemeTokens.hcLightOnError,
        link: ThemeTokens.hcLightLink,
        focus: ThemeTokens.hcLightFocus,
        navInactive: ThemeTokens.hcLightOnSurface,
        hint: ThemeTokens.hcLightOnSurface,
        bold: true,
      );

  static ThemeData get highContrastDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: ThemeTokens.hcDarkPrimary,
        onPrimary: ThemeTokens.hcDarkOnPrimary,
        secondary: ThemeTokens.hcDarkSecondary,
        onSecondary: ThemeTokens.hcDarkOnSecondary,
        surface: ThemeTokens.hcDarkSurface,
        onSurface: ThemeTokens.hcDarkOnSurface,
        scaffold: ThemeTokens.hcDarkScaffold,
        error: ThemeTokens.hcDarkError,
        onError: ThemeTokens.hcDarkOnError,
        link: ThemeTokens.hcDarkLink,
        focus: ThemeTokens.hcDarkFocus,
        navInactive: ThemeTokens.hcDarkOnSurface,
        hint: ThemeTokens.hcDarkOnSurface,
        bold: true,
      );

  /// Resolves theme for current mode + high-contrast preference.
  static ThemeData resolve({
    required ThemeMode mode,
    required bool highContrast,
    required Brightness platformBrightness,
  }) {
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    if (highContrast) {
      return isDark ? highContrastDarkTheme : highContrastTheme;
    }
    return isDark ? darkTheme : lightTheme;
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color onSecondary,
    required Color surface,
    required Color onSurface,
    required Color scaffold,
    required Color error,
    required Color onError,
    required Color link,
    required Color focus,
    required Color navInactive,
    required Color hint,
    required bool bold,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: onError,
    );

    final textTheme = ThemeTokens.textTheme(bold: bold, brightness: brightness);

    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: ThemeTokens.fontFamily,
      textTheme: textTheme,
      extensions: [
        RxMindThemeExtension(
          link: link,
          focusRing: focus,
          navInactive: navInactive,
          focusRingWidth: ThemeTokens.focusRingWidth,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 1,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: bold ? 18 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeTokens.radiusSm),
          ),
          elevation: 4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeTokens.radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: link,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: bold ? 16 : 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(ThemeTokens.spacingMd),
        hintStyle: textTheme.bodyLarge?.copyWith(color: hint),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: focus,
            width: ThemeTokens.focusRingWidth,
          ),
        ),
      ),
      focusColor: focus,
      hoverColor: focus.withValues(alpha: 0.08),
      highlightColor: focus.withValues(alpha: 0.12),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: secondary,
        unselectedItemColor: navInactive,
      ),
    );
  }
}
