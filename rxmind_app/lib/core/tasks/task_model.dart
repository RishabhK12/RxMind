class TaskModel {
  final String id;
  final String title;
  DateTime dueTime;
  bool completed;
  final bool missed;
  int snoozeCount;
  final String? recurrence;
  final String? medId;

  TaskModel({
    required this.id,
    required this.title,
    required this.dueTime,
    this.completed = false,
    this.missed = false,
    this.snoozeCount = 0,
    this.recurrence,
    this.medId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueTime': dueTime.toIso8601String(),
        'completed': completed,
        'missed': missed,
        'snoozeCount': snoozeCount,
        'recurrence': recurrence,
        'medId': medId,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        dueTime: DateTime.parse(json['dueTime']),
        completed: json['completed'] ?? false,
        missed: json['missed'] ?? false,
        snoozeCount: json['snoozeCount'] ?? 0,
        recurrence: json['recurrence'],
        medId: json['medId'],
      );
}
