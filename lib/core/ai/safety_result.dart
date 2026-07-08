enum EmergencyCategory {
  suicideSelfHarm,
  overdosePoisoning,
  acuteCardiacStroke,
  acutePainBleeding,
  emergencyIntent,
}

enum OutputSanitizeAction { pass, strip, dropEntire }

enum OutputFlag {
  prescriptionSyntax,
  dosingDirective,
  diagnosticAssertion,
  brandDoseCombo,
}

class SafetyInputResult {
  const SafetyInputResult._({
    required this.isEmergency,
    this.primary,
    this.all = const [],
  });

  factory SafetyInputResult.allowed() =>
      const SafetyInputResult._(isEmergency: false);

  factory SafetyInputResult.emergency({
    required EmergencyCategory primary,
    List<EmergencyCategory>? all,
  }) =>
      SafetyInputResult._(
        isEmergency: true,
        primary: primary,
        all: all ?? [primary],
      );

  final bool isEmergency;
  final EmergencyCategory? primary;
  final List<EmergencyCategory> all;
}

class SafetyOutputResult {
  const SafetyOutputResult({
    required this.displayText,
    required this.action,
    this.flags = const {},
    this.strippedSpanCount = 0,
  });

  factory SafetyOutputResult.pass(String text) => SafetyOutputResult(
        displayText: text,
        action: OutputSanitizeAction.pass,
      );

  factory SafetyOutputResult.strip({
    required String displayText,
    Set<OutputFlag> flags = const {},
    int strippedSpanCount = 0,
  }) =>
      SafetyOutputResult(
        displayText: displayText,
        action: OutputSanitizeAction.strip,
        flags: flags,
        strippedSpanCount: strippedSpanCount,
      );

  factory SafetyOutputResult.dropEntire({
    required String displayText,
    Set<OutputFlag> flags = const {},
  }) =>
      SafetyOutputResult(
        displayText: displayText,
        action: OutputSanitizeAction.dropEntire,
        flags: flags,
      );

  final String displayText;
  final OutputSanitizeAction action;
  final Set<OutputFlag> flags;
  final int strippedSpanCount;
}

class SafetyPipelineResult {
  const SafetyPipelineResult._({
    this.displayText,
    this.isEmergency = false,
    this.emergencyCategory,
    this.sanitizeAction,
    this.flags = const {},
    this.rateLimited = false,
    this.parseJson,
  });

  factory SafetyPipelineResult.success({
    required String displayText,
    OutputSanitizeAction? sanitizeAction,
    Set<OutputFlag> flags = const {},
    Map<String, dynamic>? parseJson,
  }) =>
      SafetyPipelineResult._(
        displayText: displayText,
        sanitizeAction: sanitizeAction,
        flags: flags,
        parseJson: parseJson,
      );

  factory SafetyPipelineResult.emergency(EmergencyCategory category) =>
      SafetyPipelineResult._(
        isEmergency: true,
        emergencyCategory: category,
      );

  factory SafetyPipelineResult.rateLimited() =>
      const SafetyPipelineResult._(rateLimited: true);

  final String? displayText;
  final bool isEmergency;
  final EmergencyCategory? emergencyCategory;
  final OutputSanitizeAction? sanitizeAction;
  final Set<OutputFlag> flags;
  final bool rateLimited;
  final Map<String, dynamic>? parseJson;
}
