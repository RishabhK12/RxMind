import 'task_model.dart';

class TaskManager {
  final List<TaskModel> _tasks = [];
  final List<Map<String, dynamic>> _taskLogs = [];

  List<TaskModel> get tasks => _tasks;
  List<Map<String, dynamic>> get taskLogs => _taskLogs;

  void createTask(TaskModel task) {
    _tasks.add(task);
    _logTask(task.id, 'created');
  }

  void markComplete(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.completed = true;
    _logTask(id, 'completed');
  }

  void snoozeTask(String id, Duration duration) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.snoozeCount += 1;
    task.dueTime = task.dueTime.add(duration);
    _logTask(id, 'snoozed');
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _logTask(id, 'deleted');
  }

  void _logTask(String id, String action) {
    _taskLogs.add({
      'taskId': id,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
