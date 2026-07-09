import 'package:sqflite_sqlcipher/sqflite.dart';

class ChatMessageRepository {
  ChatMessageRepository(this._db);

  final Database _db;

  Future<List<Map<String, dynamic>>> getSessions() async {
    final rows = await _db.rawQuery('''
      SELECT cs.session_id, cs.session_name, cs.ai_disclosure_ack,
             COALESCE(MAX(cm.created_at), cs.updated_at) as last_at
      FROM chat_sessions cs
      LEFT JOIN chat_messages cm ON cm.session_id = cs.session_id
      GROUP BY cs.session_id
      ORDER BY last_at ASC
    ''');
    if (rows.isNotEmpty) {
      return rows
          .map((r) => {
                'session_id': r['session_id'],
                'name': r['session_name'] ?? 'Chat',
                'ai_disclosure_ack': (r['ai_disclosure_ack'] as int?) == 1,
              })
          .toList();
    }

    // Legacy fallback when chat_sessions empty.
    final legacy = await _db.rawQuery('''
      SELECT session_id, session_name, MAX(created_at) as last_at
      FROM chat_messages
      GROUP BY session_id
      ORDER BY last_at ASC
    ''');
    return legacy
        .map((r) => {
              'session_id': r['session_id'],
              'name': r['session_name'] ?? 'Chat',
              'ai_disclosure_ack': false,
            })
        .toList();
  }

  Future<bool> getDisclosureAck(String sessionId) async {
    final rows = await _db.query(
      'chat_sessions',
      columns: ['ai_disclosure_ack'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return (rows.first['ai_disclosure_ack'] as int?) == 1;
  }

  Future<void> setDisclosureAck(String sessionId, bool ack) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _db.query(
      'chat_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _db.insert('chat_sessions', {
        'session_id': sessionId,
        'session_name': 'Chat',
        'ai_disclosure_ack': ack ? 1 : 0,
        'updated_at': now,
      });
    } else {
      await _db.update(
        'chat_sessions',
        {'ai_disclosure_ack': ack ? 1 : 0, 'updated_at': now},
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    final rows = await _db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return rows
        .map((r) => {
              'id': r['id'],
              'role': r['role'],
              'content': r['content'],
              'timestamp': DateTime.fromMillisecondsSinceEpoch(
                r['created_at'] as int,
              ).toIso8601String(),
            })
        .toList();
  }

  Future<void> saveSession(
    String sessionId,
    String sessionName,
    List<Map<String, dynamic>> messages,
  ) async {
    final batch = _db.batch();
    batch.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final existingAck = await getDisclosureAck(sessionId);
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgId = msg['id']?.toString() ?? '${sessionId}_$i';
      batch.insert('chat_messages', {
        'id': msgId,
        'session_id': sessionId,
        'session_name': sessionName,
        'role': msg['role'],
        'content': msg['content'],
        'created_at': DateTime.tryParse(msg['timestamp']?.toString() ?? '')
                ?.millisecondsSinceEpoch ??
            now + i,
      });
    }
    batch.insert(
      'chat_sessions',
      {
        'session_id': sessionId,
        'session_name': sessionName,
        'ai_disclosure_ack': existingAck ? 1 : 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }

  Future<void> upsertSessionMeta({
    required String sessionId,
    required String sessionName,
    bool? disclosureAck,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _db.query(
      'chat_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _db.insert('chat_sessions', {
        'session_id': sessionId,
        'session_name': sessionName,
        'ai_disclosure_ack': (disclosureAck ?? false) ? 1 : 0,
        'updated_at': now,
      });
    } else {
      final update = <String, Object?>{
        'session_name': sessionName,
        'updated_at': now,
      };
      if (disclosureAck != null) {
        update['ai_disclosure_ack'] = disclosureAck ? 1 : 0;
      }
      await _db.update(
        'chat_sessions',
        update,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  Future<void> deleteAll() async {
    await _db.delete('chat_messages');
    await _db.delete('chat_sessions');
  }
}
