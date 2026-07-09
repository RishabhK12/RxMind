import 'dart:convert';

import '../../services/discharge_data_manager.dart';

/// Builds structured CHD context for local AI — meds/tasks only, not full OCR.
class AiContextBuilder {
  AiContextBuilder._();

  static Future<String> buildStructuredContext() async {
    final meds = await DischargeDataManager.loadMedications();
    final tasks = await DischargeDataManager.loadTasks();
    final followUps = await DischargeDataManager.loadFollowUps();
    final instructions = await DischargeDataManager.loadInstructions();

    final context = <String, dynamic>{
      'medications': meds
          .map((m) => {
                'name': m['name'],
                'frequency': m['frequency'],
              })
          .toList(),
      'tasks': tasks
          .map((t) => {
                'title': t['title'],
                'due_time': t['due_time'],
              })
          .toList(),
      'follow_ups': followUps
          .map((f) => {
                'title': f['title'],
                'due_time': f['due_time'],
              })
          .toList(),
      'instructions':
          instructions.map((i) => {'content': i['content']}).toList(),
    };

    return 'STRUCTURED_CONTEXT:\n${jsonEncode(context)}';
  }
}
