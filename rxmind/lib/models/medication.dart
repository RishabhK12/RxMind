class Medication {
  final String id;
  final String name;
  final String? description;
  final String dosage;
  final String createdAt;

  Medication({
    required this.id,
    required this.name,
    this.description,
    required this.dosage,
    required this.createdAt,
  });

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    dosage: map['dosage'],
    createdAt: map['created_at'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'dosage': dosage,
    'created_at': createdAt,
  };
}
