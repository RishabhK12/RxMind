import 'task_model.dart';
// Removed unused import: 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ...existing code...

class TaskManager {
  List<TaskModel> _tasks = [];
  List<Map<String, dynamic>> _taskLogs = [];

  List<TaskModel> get tasks => _tasks;
  List<Map<String, dynamic>> get taskLogs => _taskLogs;

  void createTask(TaskModel task) {
    _tasks.add(task);
    _logTask(task.id, 'created');
    // TODO: Persist to local storage
    // TODO: Schedule notification
  }

  void markComplete(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.completed = true;
    _logTask(id, 'completed');
    // TODO: Update local storage
    // TODO: Cancel notification
  }

  void snoozeTask(String id, Duration duration) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.snoozeCount += 1;
    task.dueTime = task.dueTime.add(duration);
    _logTask(id, 'snoozed');
    // TODO: Update local storage
    // TODO: Reschedule notification
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _logTask(id, 'deleted');
    // TODO: Update local storage
    // TODO: Cancel notification
  }

  void _logTask(String id, String action) {
    _taskLogs.add({
      'taskId': id,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // TODO: Persist log
  }

  // TODO: Recurrence, missed detection, analytics, persistence
}
