import 'safety_patterns.dart';

class AiParser {
  static const schemaKeys = [
    'medications',
    'tasks',
    'follow_ups',
    'instructions',
    'warnings',
    'restrictions',
    'followups',
  ];

  static Map<String, dynamic> emptySchema() => {
        'medications': <dynamic>[],
        'tasks': <dynamic>[],
        'follow_ups': <dynamic>[],
        'instructions': <dynamic>[],
        'warnings': <dynamic>[],
        'restrictions': <dynamic>[],
      };

  static Map<String, dynamic> validateJson(Map<String, dynamic>? json) {
    final result = emptySchema();
    if (json == null) return result;

    for (final key in schemaKeys) {
      if (json.containsKey(key) && json[key] is List) {
        final normalized = key == 'followups' ? 'follow_ups' : key;
        result[normalized] = List<dynamic>.from(json[key] as List);
      }
    }
    return result;
  }

  static Map<String, dynamic> sanitizeParsedJson(Map<String, dynamic> json) {
    final meds = (json['medications'] as List?) ?? [];
    for (final item in meds) {
      if (item is Map<String, dynamic>) {
        final dose = (item['dose'] ?? item['dosage'] ?? '').toString();
        if (PrescriptivePatterns.dosingDirectives
            .any((pattern) => pattern.hasMatch(dose))) {
          item['_safety_review'] = true;
        }
      }
    }
    return json;
  }
}
