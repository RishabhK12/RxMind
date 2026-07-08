import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const guardedDirs = [
    'lib/screens/ai',
    'lib/screens/ocr',
    'lib/services/ai',
  ];

  const bannedPatterns = [
    "package:http",
    'gemini_backend_client.dart',
    'package:google_gemini',
    'backend_config.dart',
  ];

  test('AI/chat/OCR paths must not import cloud AI or HTTP', () {
    final violations = <String>[];

    for (final dirPath in guardedDirs) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final content = entity.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (!line.startsWith('import ') && !line.startsWith("import ")) {
            continue;
          }
          for (final pattern in bannedPatterns) {
            if (line.contains(pattern)) {
              violations.add('${entity.path}:${i + 1}: $line');
            }
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Banned cloud AI imports found:\n${violations.join('\n')}',
    );
  });
}
