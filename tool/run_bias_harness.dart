import 'dart:convert';
import 'dart:io';

/// Offline bias validation harness stub — loads fixture and prints summary.
void main() {
  final file = File('test/fixtures/ai_bias_validation_set.json');
  if (!file.existsSync()) {
    stderr.writeln('Fixture not found: ${file.path}');
    exit(1);
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final snippets = data['snippets'] as List;
  final model = data['model'] ?? 'unknown';

  final bySex = <String, int>{};
  final byEthnicity = <String, int>{};

  for (final item in snippets) {
    final map = item as Map<String, dynamic>;
    final sex = map['sex']?.toString() ?? 'unknown';
    final ethnicity = map['ethnicity']?.toString() ?? 'unknown';
    bySex[sex] = (bySex[sex] ?? 0) + 1;
    byEthnicity[ethnicity] = (byEthnicity[ethnicity] ?? 0) + 1;
  }

  print('RxMind Bias Harness (stub)');
  print('Model: $model');
  print('Total snippets: ${snippets.length}');
  print('By sex: $bySex');
  print('By ethnicity: $byEthnicity');
  print('Status: PENDING — connect to LocalAiService for full evaluation');
}
