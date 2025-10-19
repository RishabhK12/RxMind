class MedModel {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime nextDoseAt;
  final List<DateTime> doseHistory;
  final int adherencePercent;

  MedModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDoseAt,
    this.doseHistory = const [],
    this.adherencePercent = 100,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'nextDoseAt': nextDoseAt.toIso8601String(),
        'doseHistory': doseHistory.map((d) => d.toIso8601String()).toList(),
        'adherencePercent': adherencePercent,
      };

  factory MedModel.fromJson(Map<String, dynamic> json) => MedModel(
        id: json['id'],
        name: json['name'],
        dosage: json['dosage'],
        frequency: json['frequency'],
        nextDoseAt: DateTime.parse(json['nextDoseAt']),
        doseHistory: (json['doseHistory'] as List<dynamic>? ?? [])
            .map((d) => DateTime.parse(d))
            .toList(),
        adherencePercent: json['adherencePercent'] ?? 100,
      );
}
