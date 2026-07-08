import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safety fixture files have expected structure', () {
    final blocked = jsonDecode(
      File('test/fixtures/safety_input_blocked.json').readAsStringSync(),
    ) as List;
    final allowed = jsonDecode(
      File('test/fixtures/safety_input_allowed.json').readAsStringSync(),
    ) as List;
    final corpus = jsonDecode(
      File('test/fixtures/safety_output_corpus.json').readAsStringSync(),
    ) as List;

    expect(blocked.length, 20);
    expect(allowed.length, 20);
    expect(corpus.length, 50);

    for (final item in corpus) {
      expect(item, containsPair('text', isA<String>()));
      expect(item, containsPair('expected', isA<String>()));
    }
  });
}
