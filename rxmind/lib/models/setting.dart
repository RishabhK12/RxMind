class AppSetting {
  final String key;
  final String value;

  AppSetting({required this.key, required this.value});

  factory AppSetting.fromMap(Map<String, dynamic> map) => AppSetting(
    key: map['key'],
    value: map['value'],
  );

  Map<String, dynamic> toMap() => {
    'key': key,
    'value': value,
  };
}
