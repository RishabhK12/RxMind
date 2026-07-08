import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:rxmind_app/theme/app_theme.dart';

import 'theme_harness.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  Widget wrap(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      home: const DashboardThemeHarness(),
    );
  }

  testGoldens('Dashboard light theme golden', (tester) async {
    await tester.pumpWidgetBuilder(
      wrap(AppTheme.lightTheme),
      surfaceSize: const Size(400, 800),
    );
    await screenMatchesGolden(tester, 'dashboard_light');
  });

  testGoldens('Dashboard dark theme golden', (tester) async {
    await tester.pumpWidgetBuilder(
      wrap(AppTheme.darkTheme),
      surfaceSize: const Size(400, 800),
    );
    await screenMatchesGolden(tester, 'dashboard_dark');
  });

  testGoldens('Dashboard high-contrast theme golden', (tester) async {
    await tester.pumpWidgetBuilder(
      wrap(AppTheme.highContrastTheme),
      surfaceSize: const Size(400, 800),
    );
    await screenMatchesGolden(tester, 'dashboard_high_contrast');
  });
}
