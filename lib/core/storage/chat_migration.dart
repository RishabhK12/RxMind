import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

import 'local_storage.dart';

/// Migrates legacy `ai_chats` secure-storage blob into SQLCipher.
class ChatMigration {
  ChatMigration._();

  static Future<void> migrateFromSecureStorage(Database db) async {
    final raw = await LocalStorage.readSecure('ai_chats');
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as List;
      final batch = db.batch();
      for (var s = 0; s < decoded.length; s++) {
        final chat = decoded[s] as Map;
        final sessionId = 'session_$s';
        final sessionName = chat['name'] as String? ?? 'Chat ${s + 1}';
        final messages = chat['messages'] as List? ?? [];
        for (var m = 0; m < messages.length; m++) {
          final msg = Map<String, dynamic>.from(messages[m] as Map);
          batch.insert(
            'chat_messages',
            {
              'id': '${sessionId}_$m',
              'session_id': sessionId,
              'session_name': sessionName,
              'role': msg['role'] ?? 'user',
              'content': msg['content'] ?? '',
              'created_at': DateTime.tryParse(
                        msg['timestamp']?.toString() ?? '',
                      )?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Best-effort migration; corrupted blob is discarded.
    }

    await LocalStorage.deleteSecure('ai_chats');
  }
}
