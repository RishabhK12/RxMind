class UserProfile {
  final String name;
  final String email;
  final String? phone;
  final String? notes;

  UserProfile(
      {required this.name, required this.email, this.phone, this.notes});

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'notes': notes,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        notes: json['notes'],
      );
}
