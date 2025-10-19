import 'storage_manager.dart';
import '../tasks/task_manager.dart';
import '../meds/med_manager.dart';
import '../ai/chat_manager.dart';

class AppReset {
  static Future<void> resetAll(
      TaskManager tm, MedManager mm, ChatManager cm) async {
    // Clear all models
    tm.tasks.clear();
    tm.taskLogs.clear();
    mm.meds.clear();
    cm.clearHistory();
    await StorageManager.resetApp();
  }
}
