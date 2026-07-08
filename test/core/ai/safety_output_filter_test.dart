import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/safety_output_filter.dart';
import 'package:rxmind_app/core/ai/safety_result.dart';

void main() {
  late List<Map<String, dynamic>> corpus;

  setUp(() {
    corpus = (jsonDecode(
      File('test/fixtures/safety_output_corpus.json').readAsStringSync(),
    ) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  });

  test('corpus dosing lines are stripped or dropped', () {
    for (final item in corpus) {
      final text = item['text'] as String;
      final expected = item['expected'] as String;
      final result = SafetyOutputFilter.sanitize(text);

      if (expected == 'pass') {
        expect(result.action, OutputSanitizeAction.pass, reason: text);
      } else {
        expect(
          result.action == OutputSanitizeAction.strip ||
              result.action == OutputSanitizeAction.dropEntire,
          isTrue,
          reason: text,
        );
      }
    }
  });
}
