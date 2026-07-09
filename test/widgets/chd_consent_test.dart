import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/screens/onboarding/chd_consent_screen.dart';

void main() {
  testWidgets('CHD consent shows categories and agree button', (tester) async {
    var granted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ChdConsentScreen(
          onConsentGranted: () => granted = true,
        ),
      ),
    );

    expect(find.text('Consumer Health Data'), findsOneWidget);
    expect(find.textContaining('Discharge documents'), findsOneWidget);
    expect(find.textContaining('Medications, tasks'), findsOneWidget);
    expect(find.text('I Agree'), findsOneWidget);
    expect(find.text('View Privacy Policy'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('I Agree'));
    await tester.pumpAndSettle();

    expect(granted, isTrue);
  });
}
