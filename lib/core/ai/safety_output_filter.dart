import 'safety_patterns.dart';
import 'safety_result.dart';

class _LineScore {
  _LineScore({required this.hits, required this.flags});

  final int hits;
  final Set<OutputFlag> flags;
}

class SafetyOutputFilter {
  static const disclaimer =
      '\n\n_[Some clinical instruction language was removed for your safety. '
      'Follow your discharge paperwork and contact your clinician.]_';

  static const dropMessage =
      'I cannot provide that type of clinical instruction. '
      'Please refer to your discharge documents or contact your care team.';

  static SafetyOutputResult sanitize(String raw) {
    if (raw.trim().isEmpty) {
      return SafetyOutputResult.pass('');
    }

    var hitCount = 0;
    final flags = <OutputFlag>{};
    final lines = raw.split('\n');
    final kept = <String>[];

    for (final line in lines) {
      final severity = _scoreLine(line);
      hitCount += severity.hits;
      flags.addAll(severity.flags);

      if (severity.hits == 0) {
        kept.add(line);
      } else if (severity.hits == 1) {
        kept.add('_[line removed]_');
      } else {
        return SafetyOutputResult.dropEntire(
          displayText: dropMessage,
          flags: flags,
        );
      }
    }

    if (hitCount == 0) {
      return SafetyOutputResult.pass(raw);
    }

    final display = kept.join('\n').trim();
    if (display.isEmpty) {
      return SafetyOutputResult.dropEntire(
        displayText: dropMessage,
        flags: flags,
      );
    }

    return SafetyOutputResult.strip(
      displayText: display + disclaimer,
      flags: flags,
      strippedSpanCount: hitCount,
    );
  }

  static _LineScore _scoreLine(String line) {
    var hits = 0;
    final flags = <OutputFlag>{};

    void check(List<RegExp> patterns, OutputFlag flag, {int weight = 1}) {
      for (final p in patterns) {
        if (p.hasMatch(line)) {
          hits += weight;
          flags.add(flag);
        }
      }
    }

    check(
        PrescriptivePatterns.prescriptionHeaders, OutputFlag.prescriptionSyntax,
        weight: 2);
    check(PrescriptivePatterns.dosingDirectives, OutputFlag.dosingDirective);
    check(PrescriptivePatterns.brandDoseCombo, OutputFlag.brandDoseCombo,
        weight: 2);
    check(PrescriptivePatterns.diagnosticAssertions,
        OutputFlag.diagnosticAssertion,
        weight: 2);
    check(PrescriptivePatterns.clinicalOrders, OutputFlag.dosingDirective);

    return _LineScore(hits: hits, flags: flags);
  }
}
