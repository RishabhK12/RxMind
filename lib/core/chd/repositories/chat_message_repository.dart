import 'package:sqflite_sqlcipher/sqflite.dart';

class ChatMessageRepository {
  ChatMessageRepository(this._db);

  final Database _db;

  Future<List<Map<String, dynamic>>> getSessions() async {
    final rows = await _db.rawQuery('''
      SELECT session_id, session_name, MAX(created_at) as last_at
      FROM chat_messages
      GROUP BY session_id
      ORDER BY last_at ASC
    ''');
    return rows
        .map((r) => {
              'session_id': r['session_id'],
              'name': r['session_name'] ?? 'Chat',
            })
        .toList();
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
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      batch.insert('chat_messages', {
        'id': '${sessionId}_$i',
        'session_id': sessionId,
        'session_name': sessionName,
        'role': msg['role'],
        'content': msg['content'],
        'created_at': DateTime.tryParse(msg['timestamp']?.toString() ?? '')
                ?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    await _db.delete('chat_messages');
  }
}
