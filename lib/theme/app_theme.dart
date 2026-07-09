import 'package:flutter/material.dart';

import 'brand_shadows.dart';
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
        success: ThemeTokens.lightSuccess,
        warning: ThemeTokens.lightWarning,
        aiAccent: ThemeTokens.lightAiAccent,
        border: ThemeTokens.lightBorder,
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
        success: ThemeTokens.darkSuccess,
        warning: ThemeTokens.darkWarning,
        aiAccent: ThemeTokens.darkAiAccent,
        border: ThemeTokens.darkBorder,
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
        success: ThemeTokens.hcLightSecondary,
        warning: ThemeTokens.hcLightSecondary,
        aiAccent: ThemeTokens.hcLightPrimary,
        border: ThemeTokens.hcLightOnSurface,
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
        success: ThemeTokens.hcDarkSecondary,
        warning: ThemeTokens.hcDarkPrimary,
        aiAccent: ThemeTokens.hcDarkSecondary,
        border: ThemeTokens.hcDarkOnSurface,
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
    required Color success,
    required Color warning,
    required Color aiAccent,
    required Color border,
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
    final pill = StadiumBorder(
      side: BorderSide.none,
    );
    final softShadows = BrandShadows.softCardFor(brightness);

    final buttonText = textTheme.labelLarge?.copyWith(
      fontSize: bold ? 16 : 14,
      fontWeight: FontWeight.w700,
    );

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
          success: success,
          warning: warning,
          aiAccent: aiAccent,
          border: border,
          softShadow: softShadows,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.38),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.38),
          textStyle: buttonText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: pill,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.38),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.38),
          textStyle: buttonText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          textStyle: buttonText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: border),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: link,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: bold ? 16 : 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brightness == Brightness.dark
            ? ThemeTokens.darkMuted
            : ThemeTokens.brandMuted,
        selectedColor: primary.withValues(alpha: 0.16),
        labelStyle: textTheme.labelMedium?.copyWith(color: onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ThemeTokens.radiusLg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: brightness == Brightness.dark
              ? ThemeTokens.brandFg
              : ThemeTokens.brandCanvas,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(ThemeTokens.spacingMd),
        hintStyle: textTheme.bodyLarge?.copyWith(color: hint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
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
        selectedItemColor: primary,
        unselectedItemColor: navInactive,
      ),
    );
  }
}
