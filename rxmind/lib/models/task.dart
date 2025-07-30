class Task {
  final String id;
  final String title;
  final String? description;
  final String time;
  final String? recurrence;
  final bool completed;
  final String createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.time,
    this.recurrence,
    this.completed = false,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    time: map['time'],
    recurrence: map['recurrence'],
    completed: map['completed'] == 1,
    createdAt: map['created_at'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'time': time,
    'recurrence': recurrence,
    'completed': completed ? 1 : 0,
    'created_at': createdAt,
  };
}
