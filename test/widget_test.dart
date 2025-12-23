// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rxmind_app/main.dart';

void main() {
  testWidgets('RxMind app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const RxMindApp(showPrivacyGate: false));
    await tester.pump();
    // Allow splash timers/animations to complete to avoid pending timer failures.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
