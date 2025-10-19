import 'package:rxmind_app/services/discharge_data_manager.dart';

/// Shared compliance calculation logic to ensure consistency across the app
class ComplianceCalculator {
  /// Calculate overall compliance percentage from tasks
  static Future<Map<String, dynamic>> calculateOverallCompliance() async {
    final tasks = await DischargeDataManager.loadTasks();
    return calculateFromTasks(tasks);
  }

  /// Calculate compliance metrics from a list of tasks
  static Map<String, dynamic> calculateFromTasks(
      List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return {'percentage': 0, 'completed': 0, 'total': 0, 'overdue': 0};
    }

    final now = DateTime.now();
    int totalDueItems = 0;
    int completedItems = 0;
    int overdueItems = 0;

    // Process all tasks
    for (final task in tasks) {
      try {
        // Skip tasks without due time
        if (task['dueTime'] == null) continue;

        final isCompleted = task['completed'] == true;
        DateTime? dueTime;

        // Parse due time
        try {
          if (task['dueTime'] is DateTime) {
            dueTime = task['dueTime'] as DateTime;
          } else {
            dueTime = DateTime.parse(task['dueTime'].toString());
          }
        } catch (e) {
          continue; // Skip tasks with invalid due time
        }

        // Count this task
        totalDueItems++;

        // Count completed or overdue
        if (isCompleted) {
          completedItems++;
        } else if (dueTime.isBefore(now)) {
          overdueItems++;
        }
      } catch (e) {
        // Skip task with parsing error
      }
    }

    // Calculate compliance percentage
    final int percentage = totalDueItems > 0
        ? ((completedItems / totalDueItems) * 100).round()
        : 100;

    return {
      'percentage': percentage,
      'completed': completedItems,
      'total': totalDueItems,
      'overdue': overdueItems,
    };
  }
}
