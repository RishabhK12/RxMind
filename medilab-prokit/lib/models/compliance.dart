class Compliance {
  final String id;
  final String taskId;
  final String date;

  Compliance({
    required this.id,
    required this.taskId,
    required this.date,
  });

  factory Compliance.fromMap(Map<String, dynamic> map) => Compliance(
    id: map['id'],
    taskId: map['task_id'],
    date: map['date'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'task_id': taskId,
    'date': date,
  };
}
