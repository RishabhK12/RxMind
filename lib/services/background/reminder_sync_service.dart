import 'package:rxmind_app/core/storage/database_key_exception.dart';
import 'package:rxmind_app/core/storage/lock_safe_write_buffer.dart';
import 'package:rxmind_app/services/discharge_data_manager.dart';
import 'package:rxmind_app/services/notification_service.dart';

/// Drains [LockSafeWriteBuffer] and reschedules notifications from SQLCipher.
class ReminderSyncService {
  ReminderSyncService._();

  static Future<void> flushLockSafeBuffer() async {
    await LockSafeWriteBuffer.instance.flush(_applyPendingWrite);
  }

  static Future<void> _applyPendingWrite(PendingWrite write) async {
    if (write.operation == 'reschedule_task') {
      final taskId = write.payload['taskId'] as String?;
      if (taskId == null) return;
      try {
        final tasks = await DischargeDataManager.loadTasks();
        final task = tasks.cast<Map<String, dynamic>?>().firstWhere(
              (t) => t?['id']?.toString() == taskId,
              orElse: () => null,
            );
        if (task == null) return;
        final dueTime = task['dueTime'];
        DateTime? parsed;
        if (dueTime is DateTime) {
          parsed = dueTime;
        } else if (dueTime is String) {
          parsed = DateTime.tryParse(dueTime);
        }
        if (parsed == null) return;
        await NotificationService().scheduleTaskNotifications(
          taskId: taskId,
          taskTitle: task['title']?.toString() ?? 'Task',
          dueTime: parsed,
        );
      } on DatabaseKeyException {
        LockSafeWriteBuffer.instance.enqueue(write);
      }
    } else if (write.operation == 'reschedule_all') {
      await rescheduleAllFromDatabase();
    }
  }

  static Future<void> rescheduleAllFromDatabase() async {
    try {
      final tasks = await DischargeDataManager.loadTasks();
      await NotificationService().scheduleNotificationsForTasks(tasks);
    } on DatabaseKeyException {
      LockSafeWriteBuffer.instance.enqueue(
        PendingWrite(operation: 'reschedule_all', payload: {}),
      );
    }
  }
}
