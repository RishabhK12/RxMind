import 'storage_manager.dart';
import '../tasks/task_manager.dart';
import '../meds/med_manager.dart';
import '../ai/chat_manager.dart';

class AppReset {
  static Future<void> resetAll(
      TaskManager tm, MedManager mm, ChatManager cm) async {
    tm.tasks.clear();
    tm.taskLogs.clear();
    mm.meds.clear();
    await cm.deleteAllChats();
    await StorageManager.resetApp();
  }
}
