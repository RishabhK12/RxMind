import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  /// Clears all app data from all tables.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('medications');
    await db.delete('tasks');
    await db.delete('compliance');
    await db.delete('upload_queue');
    await db.delete('settings');
  }

  // MEDICATIONS CRUD
  Future<void> insertMedication(Map<String, dynamic> med) async {
    final db = await database;
    await db.insert('medications', med,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllMedications() async {
    final db = await database;
    return await db.query('medications', orderBy: 'created_at DESC');
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // TASKS CRUD
  Future<void> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    await db.insert('tasks', task,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'created_at DESC');
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db
        .update('tasks', task, where: 'id = ?', whereArgs: [task['id']]);
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rxmind.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE IF NOT EXISTS medications (
          id TEXT PRIMARY KEY,
          name TEXT,
          dosage TEXT,
          created_at TEXT
        )''');
        await db.execute('''CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          created_at TEXT
        )''');
        await db.execute('''CREATE TABLE IF NOT EXISTS compliance (
          id TEXT PRIMARY KEY,
          status TEXT,
          created_at TEXT
        )''');
        await db.execute('''CREATE TABLE IF NOT EXISTS upload_queue (
          id TEXT PRIMARY KEY,
          data TEXT,
          status TEXT,
          created_at TEXT
        )''');
        await db.execute('''CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )''');
      },
    );
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    if (_db != null) return _db!;
    throw Exception('Database initialization failed');
  }

  Future<List<Map<String, dynamic>>> getAllCompliance() async {
    final db = await database;
    return await db.query('compliance');
  }

  Future<int> deleteCompliance(String id) async {
    final db = await database;
    return await db.delete('compliance', where: 'id = ?', whereArgs: [id]);
  }

  // UPLOAD QUEUE CRUD
  Future<void> insertUploadQueue(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('upload_queue', item,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getQueuedUploads() async {
    final db = await database;
    return await db
        .query('upload_queue', where: 'status = ?', whereArgs: ['queued']);
  }

  Future<int> updateUploadQueueStatus(String id, String status) async {
    final db = await database;
    return await db.update('upload_queue', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUploadQueue(String id) async {
    final db = await database;
    return await db.delete('upload_queue', where: 'id = ?', whereArgs: [id]);
  }

  // SETTINGS CRUD
  Future<void> insertSetting(Map<String, dynamic> setting) async {
    final db = await database;
    await db.insert('settings', setting,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getSetting(String key) async {
    final db = await database;
    final result =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> deleteSetting(String key) async {
    final db = await database;
    return await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
