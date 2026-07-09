import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/screens/onboarding/disclaimer_gate_screen.dart';

void main() {
  testWidgets('disclaimer gate shows required text and button', (tester) async {
    var acknowledged = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DisclaimerGateScreen(
          onAcknowledged: () => acknowledged = true,
        ),
      ),
    );

    expect(
      find.text(DisclaimerGateScreen.disclaimerText),
      findsOneWidget,
    );
    expect(find.text('I Understand'), findsOneWidget);

    await tester.tap(find.text('I Understand'));
    await tester.pumpAndSettle();

    expect(acknowledged, isTrue);
  });
}
