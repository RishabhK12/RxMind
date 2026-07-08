import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

void main() {
  const minRatio = 4.5;

  group('WCAG 2.2 AA body text contrast', () {
    final pairs = <String, (Color fg, Color bg)>{
      'light onSurface/surface': (
        ThemeTokens.lightOnSurface,
        ThemeTokens.lightSurface
      ),
      'light onSurface/scaffold': (
        ThemeTokens.lightOnSurface,
        ThemeTokens.lightScaffold
      ),
      'light onPrimary/primary': (
        ThemeTokens.lightOnPrimary,
        ThemeTokens.lightPrimary
      ),
      'light onError/error': (ThemeTokens.lightOnError, ThemeTokens.lightError),
      'light link/surface': (ThemeTokens.lightLink, ThemeTokens.lightSurface),
      'dark onSurface/surface': (
        ThemeTokens.darkOnSurface,
        ThemeTokens.darkSurface
      ),
      'dark onSurface/scaffold': (
        ThemeTokens.darkOnSurface,
        ThemeTokens.darkScaffold
      ),
      'dark onPrimary/primary': (
        ThemeTokens.darkOnPrimary,
        ThemeTokens.darkPrimary
      ),
      'dark onError/error': (ThemeTokens.darkOnError, ThemeTokens.darkError),
      'hcLight onSurface/surface': (
        ThemeTokens.hcLightOnSurface,
        ThemeTokens.hcLightSurface
      ),
      'hcLight onPrimary/primary': (
        ThemeTokens.hcLightOnPrimary,
        ThemeTokens.hcLightPrimary
      ),
      'hcDark onSurface/surface': (
        ThemeTokens.hcDarkOnSurface,
        ThemeTokens.hcDarkSurface
      ),
      'hcDark onPrimary/primary': (
        ThemeTokens.hcDarkOnPrimary,
        ThemeTokens.hcDarkPrimary
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} ≥ $minRatio:1', () {
        final ratio = ThemeTokens.contrastRatio(entry.value.$1, entry.value.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(minRatio),
          reason: '${entry.key} ratio was $ratio',
        );
      });
    }
  });

  test('focus ring width is 3px', () {
    expect(ThemeTokens.focusRingWidth, 3.0);
  });
}
