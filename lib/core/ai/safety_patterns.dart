class SafetyPatterns {
  SafetyPatterns._();

  static final List<RegExp> suicideSelfHarm = [
    RegExp(r'\b(kill|hurt|harm|end)\s+(my)?self\b'),
    RegExp(r'\bsuicid(e|al)\b'),
    RegExp(r'\bwant\s+to\s+die\b'),
    RegExp(r"\bdon'?t\s+want\s+to\s+live\b"),
    RegExp(r'\bself[\s-]?harm\b'),
    RegExp(r'\bcut(ting)?\s+myself\b'),
    RegExp(r'\b988\b'),
    RegExp(r'\bno\s+reason\s+to\s+live\b'),
  ];

  static final List<RegExp> overdosePoisoning = [
    RegExp(r'\boverdose(d|ing)?\b'),
    RegExp(r'\btoo\s+many\s+(pills|tablets|meds|medications)\b'),
    RegExp(r'\btook\s+all\s+(my|the)\s+(pills|meds)\b'),
    RegExp(r'\bpoison(ed|ing)?\b'),
    RegExp(r'\bswallowed\s+(a\s+)?bottle\b'),
  ];

  static final List<RegExp> acuteCardiacStroke = [
    RegExp(r'\bheart\s+attack\b'),
    RegExp(r'\bchest\s+pain\b'),
    RegExp(r"\bcan'?t\s+breathe\b"),
    RegExp(r'\bstroke\b'),
    RegExp(r'\bface\s+drooping\b'),
    RegExp(r'\barm\s+weakness\b'),
    RegExp(r'\bslurred\s+speech\b'),
    RegExp(r'\bpassed\s+out\b'),
    RegExp(r'\bunconscious\b'),
  ];

  static final List<RegExp> acutePainBleeding = [
    RegExp(r'\bsevere\s+(pain|bleeding|headache)\b'),
    RegExp(r'\bworst\s+headache\b'),
    RegExp(r"\bcan'?t\s+stop\s+bleeding\b"),
    RegExp(r'\bvomiting\s+blood\b'),
    RegExp(r'\bthoughts\s+of\s+hurting\s+others\b'),
  ];

  static final List<RegExp> emergencyIntent = [
    RegExp(r'\b(call\s+)?911\b'),
    RegExp(r'\bemergency\s+room\b'),
    RegExp(r'\b(er|ed)\s+now\b'),
    RegExp(r'\bneed\s+ambulance\b'),
    RegExp(r'\blife\s+threatening\b'),
  ];
}

class PrescriptivePatterns {
  PrescriptivePatterns._();

  static final List<RegExp> prescriptionHeaders = [
    RegExp(r'\bRx\s*[:#]?\s*\d*', caseSensitive: false),
    RegExp(r'\bDISPENSE\s*[:#]', caseSensitive: false),
    RegExp(r'\bSIG\s*[:#]', caseSensitive: false),
    RegExp(r'\bNDC\s*[:#]?\s*\d', caseSensitive: false),
    RegExp(r'\bDEA\s*[:#]?\s*[A-Z]{2}\d', caseSensitive: false),
  ];

  static final List<RegExp> dosingDirectives = [
    RegExp(
      r'\b(take|use|apply|inject|inhale)\s+\d+(\.\d+)?\s*(mg|mcg|g|ml|mL|units?|tablets?|capsules?|puffs?|drops?)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b\d+(\.\d+)?\s*(mg|mcg|g|ml|mL)\s*(po|by mouth|orally|twice|daily|bid|tid|qid|prn|every)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(increase|decrease|double|halve|titrate)\s+(the\s+|your\s+)?(dose|dosage|medication)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b(start|stop|discontinue|switch)\s+(to\s+)?(a\s+)?(new\s+)?(taking\s+)?(your\s+)?(medication|meds|prescription)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(max(imum)?\s+daily\s+dose)\b', caseSensitive: false),
  ];

  static final List<RegExp> brandDoseCombo = [
    RegExp(
      r'\b(lipitor|metformin|lisinopril|amlodipine|omeprazole|atorvastatin|levothyroxine|gabapentin|hydrocodone|oxycodone|albuterol|insulin)\b.{0,40}\b\d+\s*(mg|mcg|units?)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\b\d+\s*(mg|mcg|units?)\b.{0,40}\b(lipitor|metformin|lisinopril|amlodipine|omeprazole|atorvastatin)\b',
      caseSensitive: false,
    ),
  ];

  static final List<RegExp> diagnosticAssertions = [
    RegExp(
      r'\byou\s+(have|likely\s+have|probably\s+have)\s+[a-z]+(\s+[a-z]+){0,4}\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\bthis\s+(is|sounds\s+like)\s+(a\s+)?(heart\s+attack|stroke|infection|sepsis|diabetes)\b',
      caseSensitive: false,
    ),
    RegExp(r'\bi\s+diagnose\b', caseSensitive: false),
    RegExp(r'\byour\s+condition\s+is\b', caseSensitive: false),
  ];

  static final List<RegExp> clinicalOrders = [
    RegExp(r'\b(go\s+to|visit)\s+(the\s+)?(er|emergency)\b',
        caseSensitive: false),
    RegExp(r'\byou\s+should\s+(take|start|begin|use)\s+\d',
        caseSensitive: false),
    RegExp(r'\bprescribe(d|s)?\s+(you|a)\b', caseSensitive: false),
  ];
}

String normalizeForSafety(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\w\s\.\,\!\?\-]'), '')
      .trim();
}
