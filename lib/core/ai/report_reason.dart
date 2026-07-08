enum ReportReason {
  incorrectHealthInfo('incorrect_health_info', 'Incorrect health information'),
  unsafeMedicalAdvice('unsafe_medical_advice', 'Unsafe medical advice'),
  offTopic('off_topic', 'Off topic'),
  other('other', 'Other');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}
