import '../tasks/task_manager.dart';
import '../meds/med_manager.dart';

class StatsManager {
  // Example: Calculate completion rate
  static double taskCompletionRate(TaskManager tm) {
    final total = tm.tasks.length;
    final completed = tm.tasks.where((t) => t.completed).length;
    return total == 0 ? 0 : (completed / total) * 100;
  }

  static double medAdherenceRate(MedManager mm) {
    final total = mm.meds.length;
    final adherent = mm.meds.where((m) => m.adherencePercent >= 80).length;
    return total == 0 ? 0 : (adherent / total) * 100;
  }
}
