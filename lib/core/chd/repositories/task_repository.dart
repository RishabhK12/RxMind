import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

abstract class TaskRepositoryBase {
  Future<List<Map<String, dynamic>>> getAll();
  Future<void> replaceAll(List<Map<String, dynamic>> items);
  Future<void> deleteAll();
}

class TaskRepository implements TaskRepositoryBase {
  TaskRepository(this._db);

  final Database _db;

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('tasks', orderBy: 'updated_at DESC');
    return rows.map(_rowToMap).toList();
  }

  @override
  Future<void> replaceAll(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    batch.delete('tasks');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < items.length; i++) {
      final item = Map<String, dynamic>.from(items[i]);
      if (item['dueTime'] is DateTime) {
        item['dueTime'] = (item['dueTime'] as DateTime).toIso8601String();
      }
      batch.insert('tasks', {
        'id': item['id']?.toString() ?? 'task_$i',
        'title': item['title']?.toString() ?? item['name']?.toString() ?? '',
        'due_time': item['dueTime']?.toString() ?? item['dueDate']?.toString(),
        'completed':
            (item['completed'] == true || item['isCompleted'] == true) ? 1 : 0,
        'payload_json': jsonEncode(item),
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete('tasks');
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
      'completed': row['completed'] == 1,
    };
  }
}
