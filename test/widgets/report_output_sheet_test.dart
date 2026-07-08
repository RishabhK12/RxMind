import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/report_reason.dart';
import 'package:rxmind_app/screens/ai/report_output_sheet.dart';

void main() {
  testWidgets('report sheet submits selected reason', (tester) async {
    ReportReason? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showReportOutputSheet(
                  context: context,
                  onSubmit: (reason, note) async {
                    submitted = reason;
                  },
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(ReportReason.offTopic.label));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(submitted, ReportReason.offTopic);
  });
}
