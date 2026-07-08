import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

class FollowUpRepository {
  FollowUpRepository(this._db);

  final Database _db;

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('follow_ups', orderBy: 'updated_at DESC');
    return rows.map(_rowToMap).toList();
  }

  Future<void> replaceAll(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    batch.delete('follow_ups');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      batch.insert('follow_ups', {
        'id': item['id']?.toString() ?? 'fu_$i',
        'title': item['title']?.toString() ?? item['name']?.toString() ?? '',
        'due_time': item['dueTime']?.toString() ?? item['date']?.toString(),
        'payload_json': jsonEncode(item),
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    await _db.delete('follow_ups');
  }

  Map<String, dynamic> _rowToMap(Map<String, Object?> row) {
    if (row['payload_json'] != null) {
      return Map<String, dynamic>.from(
        jsonDecode(row['payload_json'] as String) as Map,
      );
    }
    return {
      'id': row['id'],
      'title': row['title'],
      'dueTime': row['due_time'],
    };
  }
}
