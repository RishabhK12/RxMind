import 'safety_patterns.dart';
import 'safety_result.dart';

class SafetyInputFilter {
  static SafetyInputResult evaluate(String rawUserText) {
    final text = normalizeForSafety(rawUserText);
    if (text.isEmpty) return SafetyInputResult.allowed();

    final hits = <EmergencyCategory>[];

    if (_anyMatch(text, SafetyPatterns.suicideSelfHarm)) {
      hits.add(EmergencyCategory.suicideSelfHarm);
    }
    if (_anyMatch(text, SafetyPatterns.overdosePoisoning)) {
      hits.add(EmergencyCategory.overdosePoisoning);
    }
    if (_anyMatch(text, SafetyPatterns.acuteCardiacStroke)) {
      hits.add(EmergencyCategory.acuteCardiacStroke);
    }
    if (_anyMatch(text, SafetyPatterns.acutePainBleeding)) {
      hits.add(EmergencyCategory.acutePainBleeding);
    }
    if (_anyMatch(text, SafetyPatterns.emergencyIntent)) {
      final standaloneEmergency = RegExp(
        r'\b(911|emergency\s+room|need\s+ambulance|life\s+threatening)\b',
      ).hasMatch(text);
      if (hits.isNotEmpty || standaloneEmergency) {
        hits.add(EmergencyCategory.emergencyIntent);
      }
    }

    if (hits.isNotEmpty) {
      return SafetyInputResult.emergency(primary: hits.first, all: hits);
    }
    return SafetyInputResult.allowed();
  }

  static bool _anyMatch(String text, List<RegExp> patterns) {
    for (final p in patterns) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }
}
