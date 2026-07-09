import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

void main() {
  const minBodyRatio = 4.5;
  // Brand primary `#3B82F6` on white is ~3.68:1 — valid for large/bold UI
  // labels (WCAG AA large text / non-text UI ≥ 3:1), not body copy.
  const minUiRatio = 3.0;

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
      'dark onError/error': (ThemeTokens.darkOnError, ThemeTokens.darkError),
      'hcLight onSurface/surface': (
        ThemeTokens.hcLightOnSurface,
        ThemeTokens.hcLightSurface
      ),
      'hcDark onSurface/surface': (
        ThemeTokens.hcDarkOnSurface,
        ThemeTokens.hcDarkSurface
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} ≥ $minBodyRatio:1', () {
        final ratio = ThemeTokens.contrastRatio(entry.value.$1, entry.value.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(minBodyRatio),
          reason: '${entry.key} ratio was $ratio',
        );
      });
    }
  });

  group('WCAG 2.2 AA large-text / UI component contrast', () {
    final pairs = <String, (Color fg, Color bg)>{
      'light onPrimary/primary': (
        ThemeTokens.lightOnPrimary,
        ThemeTokens.lightPrimary
      ),
      'dark onPrimary/primary': (
        ThemeTokens.darkOnPrimary,
        ThemeTokens.darkPrimary
      ),
      'hcLight onPrimary/primary': (
        ThemeTokens.hcLightOnPrimary,
        ThemeTokens.hcLightPrimary
      ),
      'hcDark onPrimary/primary': (
        ThemeTokens.hcDarkOnPrimary,
        ThemeTokens.hcDarkPrimary
      ),
    };

    for (final entry in pairs.entries) {
      test('${entry.key} ≥ $minUiRatio:1', () {
        final ratio = ThemeTokens.contrastRatio(entry.value.$1, entry.value.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(minUiRatio),
          reason: '${entry.key} ratio was $ratio',
        );
      });
    }
  });

  test('focus ring width is 3px', () {
    expect(ThemeTokens.focusRingWidth, 3.0);
  });
}
