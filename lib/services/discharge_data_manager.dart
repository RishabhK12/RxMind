import 'package:sqflite_sqlcipher/sqflite.dart';

import '../core/chd/repositories/app_metadata_repository.dart';
import '../core/chd/repositories/contact_repository.dart';
import '../core/chd/repositories/follow_up_repository.dart';
import '../core/chd/repositories/instruction_repository.dart';
import '../core/chd/repositories/medication_repository.dart';
import '../core/chd/repositories/ocr_text_repository.dart';
import '../core/chd/repositories/profile_repository.dart';
import '../core/chd/repositories/task_repository.dart';
import '../core/chd/repositories/warning_repository.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/sqlcipher_database.dart';

/// Manages discharge data persistence via encrypted SQLCipher.
class DischargeDataManager {
  static final List<Function()> _taskUpdateListeners = [];

  static const retainRawOcrKey = 'retain_raw_ocr';

  static void addTaskUpdateListener(Function() listener) {
    _taskUpdateListeners.add(listener);
  }

  static void removeTaskUpdateListener(Function() listener) {
    _taskUpdateListeners.remove(listener);
  }

  static void _notifyTaskUpdateListeners() {
    for (final listener in _taskUpdateListeners) {
      listener();
    }
  }

  static Future<Database> _db() => SecureDatabase.instance();

  static Future<AppMetadataRepository> _meta() async =>
      AppMetadataRepository(await _db());

  static Future<bool> shouldRetainRawOcr() async {
    final meta = await _meta();
    return await meta.get(retainRawOcrKey) == 'true';
  }

  static Future<void> setRetainRawOcr(bool retain) async {
    final meta = await _meta();
    await meta.set(retainRawOcrKey, retain.toString());
  }

  static Future<void> saveDischargeData({
    required List<Map<String, dynamic>> medications,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> followUps,
    required List<Map<String, dynamic>> instructions,
    String? rawOcrText,
  }) async {
    final db = await _db();
    final meta = AppMetadataRepository(db);

    await meta.set('discharge_uploaded', 'true');
    await MedicationRepository(db).replaceAll(medications);
    await TaskRepository(db).replaceAll(tasks);
    await FollowUpRepository(db).replaceAll(followUps);
    await InstructionRepository(db).replaceAll(instructions);

    if (rawOcrText != null && await shouldRetainRawOcr()) {
      await OcrTextRepository(db).save(rawOcrText);
    } else {
      await OcrTextRepository(db).delete();
    }

    _notifyTaskUpdateListeners();
  }

  static Future<void> saveProfileData({
    String? name,
    int? height,
    int? weight,
    int? age,
    String? sex,
    String? bedtime,
    String? wakeTime,
  }) async {
    final db = await _db();
    final repo = ProfileRepository(db);
    final existing = await repo.get();
    await repo.upsert({
      'name': name ?? existing['name'],
      'height': height ?? existing['height'],
      'weight': weight ?? existing['weight'],
      'age': age ?? existing['age'],
      'sex': sex ?? existing['sex'],
      'bedtime': bedtime ?? existing['bedtime'],
      'wakeTime': wakeTime ?? existing['wakeTime'],
    });
  }

  static Future<Map<String, dynamic>> loadProfileData() async {
    final db = await _db();
    return ProfileRepository(db).get();
  }

  static Future<String?> loadRawOcrText() async {
    if (!await shouldRetainRawOcr()) return null;
    final db = await _db();
    return OcrTextRepository(db).get();
  }

  static Future<bool> isDischargeUploaded() async {
    final meta = await _meta();
    return await meta.get('discharge_uploaded') == 'true';
  }

  static Future<List<Map<String, dynamic>>> loadMedications() async {
    final db = await _db();
    return MedicationRepository(db).getAll();
  }

  static Future<void> saveMedications(
      List<Map<String, dynamic>> medications) async {
    final db = await _db();
    await MedicationRepository(db).replaceAll(medications);
    _notifyTaskUpdateListeners();
  }

  static Future<List<Map<String, dynamic>>> loadTasks() async {
    final db = await _db();
    return TaskRepository(db).getAll();
  }

  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final db = await _db();
    await TaskRepository(db).replaceAll(tasks);
    _notifyTaskUpdateListeners();
  }

  static int getTaskUpdateListenersCount() => _taskUpdateListeners.length;

  static Future<List<Map<String, dynamic>>> loadFollowUps() async {
    final db = await _db();
    return FollowUpRepository(db).getAll();
  }

  static Future<List<Map<String, dynamic>>> loadInstructions() async {
    final db = await _db();
    return InstructionRepository(db).getAll();
  }

  static Future<void> saveContacts(List<Map<String, dynamic>> contacts) async {
    final db = await _db();
    await ContactRepository(db).replaceAll(contacts);
  }

  static Future<List<Map<String, dynamic>>> loadContacts() async {
    final db = await _db();
    return ContactRepository(db).getAll();
  }

  static Future<void> saveWarnings(List<Map<String, dynamic>> warnings) async {
    final db = await _db();
    await WarningRepository(db).replaceAll(warnings);
  }

  static Future<List<Map<String, dynamic>>> loadWarnings() async {
    final db = await _db();
    return WarningRepository(db).getAll();
  }

  static Future<void> purgeRawOcrText() async {
    final db = await _db();
    await OcrTextRepository(db).delete();
  }

  /// Clears CHD tables (used during partial reset flows).
  static Future<void> clearDischargeData() async {
    final db = await _db();
    await MedicationRepository(db).deleteAll();
    await TaskRepository(db).deleteAll();
    await FollowUpRepository(db).deleteAll();
    await InstructionRepository(db).deleteAll();
    await ContactRepository(db).deleteAll();
    await WarningRepository(db).deleteAll();
    await ProfileRepository(db).deleteAll();
    await OcrTextRepository(db).delete();
    final meta = AppMetadataRepository(db);
    await meta.delete('discharge_uploaded');
    await LocalStorage.deleteSecure('ai_chats');
  }
}
