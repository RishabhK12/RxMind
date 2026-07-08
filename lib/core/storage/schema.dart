import 'package:sqflite_sqlcipher/sqflite.dart';

/// SQLCipher schema for all Consumer Health Data tables.
class Schema {
  Schema._();

  static const int version = 1;

  static const String medications = '''
    CREATE TABLE IF NOT EXISTS medications (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      dose TEXT,
      frequency TEXT,
      payload_json TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String tasks = '''
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      due_time TEXT,
      completed INTEGER NOT NULL DEFAULT 0,
      payload_json TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String followUps = '''
    CREATE TABLE IF NOT EXISTS follow_ups (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      due_time TEXT,
      payload_json TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String instructions = '''
    CREATE TABLE IF NOT EXISTS instructions (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      payload_json TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String contacts = '''
    CREATE TABLE IF NOT EXISTS contacts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT,
      payload_json TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String warnings = '''
    CREATE TABLE IF NOT EXISTS warnings (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      payload_json TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String profile = '''
    CREATE TABLE IF NOT EXISTS profile (
      id TEXT PRIMARY KEY DEFAULT 'default',
      name TEXT,
      height INTEGER,
      weight INTEGER,
      age INTEGER,
      sex TEXT,
      bedtime TEXT,
      wake_time TEXT,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String ocrText = '''
    CREATE TABLE IF NOT EXISTS ocr_text (
      id TEXT PRIMARY KEY DEFAULT 'default',
      content TEXT,
      updated_at INTEGER
    )
  ''';

  static const String chatMessages = '''
    CREATE TABLE IF NOT EXISTS chat_messages (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      session_name TEXT,
      role TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''';

  static const String appMetadata = '''
    CREATE TABLE IF NOT EXISTS app_metadata (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static Future<void> createAll(Database db, int version) async {
    await db.execute(medications);
    await db.execute(tasks);
    await db.execute(followUps);
    await db.execute(instructions);
    await db.execute(contacts);
    await db.execute(warnings);
    await db.execute(profile);
    await db.execute(ocrText);
    await db.execute(chatMessages);
    await db.execute(appMetadata);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_session ON chat_messages(session_id)',
    );
  }
}
