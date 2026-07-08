import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/main.dart';
import 'package:rxmind_app/screens/onboarding/disclaimer_gate_screen.dart';
import 'package:rxmind_app/screens/onboarding/onboarding_wizard_screen.dart';

void main() {
  testWidgets('onboarding wizard shows disclaimer text on step 2',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RxMindSettings(
          themeMode: ThemeMode.light,
          highContrast: false,
          textScale: 1.0,
          reducedMotion: true,
          updateTheme: (_) {},
          updateHighContrast: (_) {},
          updateTextScale: (_) {},
          updateReducedMotion: (_) {},
          child: OnboardingWizardScreen(
            initialStep: 1,
            onDisclaimerAcknowledged: () async {},
            onConsentGranted: () async {},
            onComplete: () {},
          ),
        ),
      ),
    );

    expect(find.text(DisclaimerGateScreen.disclaimerText), findsOneWidget);
    expect(find.text('I Understand'), findsOneWidget);
  });

  testWidgets('onboarding wizard shows progress indicator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingWizardScreen(
          onDisclaimerAcknowledged: () async {},
          onConsentGranted: () async {},
          onComplete: () {},
        ),
      ),
    );

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
