import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/screens/ai/ai_disclosure_banner.dart';

void main() {
  testWidgets('disclosure banner requires acknowledgment tap', (tester) async {
    var acknowledged = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiDisclosureBanner(
            onAcknowledged: () => acknowledged = true,
          ),
        ),
      ),
    );

    expect(acknowledged, isFalse);
    expect(find.text(AiDisclosureBanner.disclosureText), findsOneWidget);

    await tester.tap(find.text('I Understand'));
    await tester.pump();

    expect(acknowledged, isTrue);
  });
}
