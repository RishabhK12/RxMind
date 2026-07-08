import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('export progress uses live region semantics', (tester) async {
    const status = 'Generating health report PDF';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Semantics(
            liveRegion: true,
            label: status,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(CircularProgressIndicator));
    expect(semantics.label, status);
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
  });
}
