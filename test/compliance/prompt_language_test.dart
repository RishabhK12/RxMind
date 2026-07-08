import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const promptFiles = [
    'lib/core/ai/wellness_prompts.dart',
    'lib/screens/ai/ai_chat_screen.dart',
    'lib/screens/ocr/parsing_progress.dart',
  ];

  final bannedPattern = RegExp(
    r'(hipaa-compliant|diagnos|dosage|prescri|clinical decision|medical advice|treatment plan|medical assistant)',
    caseSensitive: false,
  );

  test('prompt source files must not contain banned clinical language', () {
    final violations = <String>[];

    for (final path in promptFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        violations.add('$path: file not found');
        continue;
      }

      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (bannedPattern.hasMatch(line)) {
          violations.add('${path}:${i + 1}: $line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Banned prompt language found:\n${violations.join('\n')}',
    );
  });
}
