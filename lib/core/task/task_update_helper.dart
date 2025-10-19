import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/core/stats/compliance_calculator.dart';

/// Helper class for task updates with consistent calculation
class TaskUpdateHelper {
  /// Updates task completion status and notifies all relevant parts of the app
  static Future<Map<String, dynamic>> updateTaskCompletion({
    required List<Map<String, dynamic>> tasks,
    required Map<String, dynamic> task,
    required bool completed,
  }) async {
    // Find the task in the list by ID
    final int index = tasks.indexWhere((t) => t['id'] == task['id']);
    if (index == -1) {
      // Task not found - this shouldn't happen but handle it gracefully
      // Just update the task object and add it to the list
      task['completed'] = completed;
      if (completed) {
        final now = DateTime.now();
        task['lastCompleted'] = now.toIso8601String();
        if (task['isRecurring'] == true) {
          _updateRecurringTaskSchedule(task);
        }
      }
      tasks.add(task);
      await DischargeDataManager.saveTasks(tasks);
      return task;
    }

    // Get the original task from the list to preserve all fields
    final originalTask = tasks[index];

    // Update the completion status while preserving all other fields
    final updatedTask = {
      ...originalTask, // Start with all original fields
      'completed': completed,
    };

    // If completing task, record completion time
    if (completed) {
      final now = DateTime.now();
      updatedTask['lastCompleted'] = now.toIso8601String();

      // Handle recurring task updates if needed
      if (updatedTask['isRecurring'] == true) {
        _updateRecurringTaskSchedule(updatedTask);
      }
    } else {
      // If marking as incomplete, clear completion time and recurring schedule
      updatedTask['lastCompleted'] = null;
      updatedTask['nextOccurrence'] = null;
      updatedTask['showAfter'] = null;
    }

    // Update the task in the list
    tasks[index] = updatedTask;

    // Save tasks to persistent storage
    await DischargeDataManager.saveTasks(tasks);

    // Get updated compliance metrics
    final updatedCompliance =
        await ComplianceCalculator.calculateOverallCompliance();

    return {
      ...updatedTask,
      'updatedCompliance': updatedCompliance,
    };
  }

  /// Calculate next occurrence for recurring tasks
  static void _updateRecurringTaskSchedule(Map<String, dynamic> task) {
    try {
      // Calculate next occurrence based on recurring pattern
      DateTime? nextDueTime;
      final recurringPattern = task['recurringPattern'];
      final interval = task['recurringInterval'] as int? ?? 1;

      if (task['dueTime'] != null) {
        DateTime currentDue;
        if (task['dueTime'] is DateTime) {
          currentDue = task['dueTime'] as DateTime;
        } else {
          currentDue = DateTime.parse(task['dueTime'].toString());
        }

        if (recurringPattern == 'hourly') {
          nextDueTime = currentDue.add(Duration(hours: interval));
        } else if (recurringPattern == 'daily') {
          nextDueTime = currentDue.add(Duration(days: interval));
        } else if (recurringPattern == 'weekly') {
          nextDueTime = currentDue.add(Duration(days: 7 * interval));
        } else if (recurringPattern == 'monthly') {
          nextDueTime = DateTime(
              currentDue.year, currentDue.month + interval, currentDue.day);
        }
      }

      // Mark task to reappear at next occurrence
      if (nextDueTime != null) {
        task['nextOccurrence'] = nextDueTime.toIso8601String();
        task['showAfter'] = nextDueTime.toIso8601String();
      }
    } catch (e) {
      // Handle error calculating next occurrence
    }
  }
}
