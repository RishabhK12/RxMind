import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../chd/repositories/app_metadata_repository.dart';
import '../chd/repositories/contact_repository.dart';
import '../chd/repositories/instruction_repository.dart';
import '../chd/repositories/medication_repository.dart';
import '../chd/repositories/profile_repository.dart';
import '../chd/repositories/task_repository.dart';
import '../chd/repositories/warning_repository.dart';
import 'chat_migration.dart';

/// One-time migration from legacy SharedPreferences CHD keys to SQLCipher.
class MigrationV1 {
  MigrationV1._();

  static const migrationKey = 'migration_v1_complete';

  static const _legacyKeys = [
    'dischargeUploaded',
    'medications',
    'tasks',
    'followUps',
    'instructions',
    'userName',
    'userHeight',
    'userWeight',
    'userAge',
    'userSex',
    'userBedtime',
    'userWakeTime',
    'rawOcrText',
    'contacts',
    'warnings',
  ];

  static Future<void> runIfNeeded(Database db) async {
    final meta = AppMetadataRepository(db);
    if (await meta.get(migrationKey) == 'true') return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    final medRepo = MedicationRepository(db);
    final taskRepo = TaskRepository(db);
    final profileRepo = ProfileRepository(db);
    final contactRepo = ContactRepository(db);
    final warningRepo = WarningRepository(db);
    final instructionRepo = InstructionRepository(db);

    final medsJson = prefs.getString('medications');
    if (medsJson != null) {
      final list = jsonDecode(medsJson) as List;
      await medRepo.replaceAll(
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    }

    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final list = jsonDecode(tasksJson) as List;
      await taskRepo.replaceAll(
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    }

    final followUpsJson = prefs.getString('followUps');
    if (followUpsJson != null) {
      final list = jsonDecode(followUpsJson) as List;
      for (var i = 0; i < list.length; i++) {
        final item = Map<String, dynamic>.from(list[i] as Map);
        await db.insert(
          'follow_ups',
          {
            'id': item['id']?.toString() ?? 'fu_$i',
            'title':
                item['title']?.toString() ?? item['name']?.toString() ?? '',
            'due_time': item['dueTime']?.toString() ?? item['date']?.toString(),
            'payload_json': jsonEncode(item),
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    final instructionsJson = prefs.getString('instructions');
    if (instructionsJson != null) {
      final list = jsonDecode(instructionsJson) as List;
      await instructionRepo.replaceAll(
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    }

    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final list = jsonDecode(contactsJson) as List;
      await contactRepo.replaceAll(
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    }

    final warningsJson = prefs.getString('warnings');
    if (warningsJson != null) {
      final list = jsonDecode(warningsJson) as List;
      await warningRepo.replaceAll(
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    }

    await profileRepo.upsert({
      'name': prefs.getString('userName'),
      'height': prefs.getInt('userHeight'),
      'weight': prefs.getInt('userWeight'),
      'age': prefs.getInt('userAge'),
      'sex': prefs.getString('userSex'),
      'bedtime': prefs.getString('userBedtime'),
      'wakeTime': prefs.getString('userWakeTime'),
    });

    final rawOcr = prefs.getString('rawOcrText');
    if (rawOcr != null && rawOcr.isNotEmpty) {
      await db.insert(
        'ocr_text',
        {
          'id': 'default',
          'content': rawOcr,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    if (prefs.getBool('dischargeUploaded') == true) {
      await meta.set('discharge_uploaded', 'true');
    }

    await ChatMigration.migrateFromSecureStorage(db);

    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }

    await meta.set(migrationKey, 'true');
  }
}
