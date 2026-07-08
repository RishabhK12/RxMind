import 'package:sqflite_sqlcipher/sqflite.dart';

import '../chd/repositories/app_metadata_repository.dart';
import 'schema.dart';

/// Schema v2: chat_sessions metadata + ai_reports audit table.
class MigrationV2 {
  MigrationV2._();

  static const migrationKey = 'migration_v2_complete';

  static Future<void> runIfNeeded(Database db) async {
    final meta = AppMetadataRepository(db);
    if (await meta.get(migrationKey) == 'true') return;

    await _ensureTables(db);
    await _backfillChatSessions(db);
    await meta.set(migrationKey, 'true');
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _ensureTables(db);
      await _backfillChatSessions(db);
      final meta = AppMetadataRepository(db);
      await meta.set(migrationKey, 'true');
    }
  }

  static Future<void> _ensureTables(Database db) async {
    await db.execute(Schema.chatSessions);
    await db.execute(Schema.aiReports);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_reports_message ON ai_reports(message_id)',
    );
  }

  static Future<void> _backfillChatSessions(Database db) async {
    final rows = await db.rawQuery('''
      SELECT session_id, session_name, MAX(created_at) as last_at
      FROM chat_messages
      GROUP BY session_id
    ''');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final row in rows) {
      final sessionId = row['session_id'] as String;
      final existing = await db.query(
        'chat_sessions',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      if (existing.isEmpty) {
        await db.insert('chat_sessions', {
          'session_id': sessionId,
          'session_name': row['session_name'] ?? 'Chat',
          'ai_disclosure_ack': 0,
          'updated_at': row['last_at'] ?? now,
        });
      }
    }
  }
}
