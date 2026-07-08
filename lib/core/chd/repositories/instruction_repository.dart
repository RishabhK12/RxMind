import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

class InstructionRepository {
  InstructionRepository(this._db);

  final Database _db;

  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('instructions', orderBy: 'updated_at DESC');
    return rows.map(_rowToMap).toList();
  }

  Future<void> replaceAll(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    batch.delete('instructions');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      batch.insert('instructions', {
        'id': item['id']?.toString() ?? 'instr_$i',
        'content': item['content']?.toString() ??
            item['instruction']?.toString() ??
            item['text']?.toString() ??
            '',
        'payload_json': jsonEncode(item),
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAll() async {
    await _db.delete('instructions');
  }

  Map<String, dynamic> _rowToMap(Map<String, Object?> row) {
    if (row['payload_json'] != null) {
      return Map<String, dynamic>.from(
        jsonDecode(row['payload_json'] as String) as Map,
      );
    }
    return {'id': row['id'], 'content': row['content']};
  }
}
