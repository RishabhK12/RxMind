import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/safety_input_filter.dart';

void main() {
  late List<String> blocked;
  late List<String> allowed;

  setUp(() {
    blocked = List<String>.from(
      jsonDecode(
        File('test/fixtures/safety_input_blocked.json').readAsStringSync(),
      ) as List,
    );
    allowed = List<String>.from(
      jsonDecode(
        File('test/fixtures/safety_input_allowed.json').readAsStringSync(),
      ) as List,
    );
  });

  test('blocked fixtures route to emergency', () {
    for (final query in blocked) {
      final result = SafetyInputFilter.evaluate(query);
      expect(
        result.isEmergency,
        isTrue,
        reason: 'Expected emergency for: $query',
      );
    }
  });

  test('allowed fixtures proceed without emergency', () {
    for (final query in allowed) {
      final result = SafetyInputFilter.evaluate(query);
      expect(
        result.isEmergency,
        isFalse,
        reason: 'Expected allowed for: $query',
      );
    }
  });
}
