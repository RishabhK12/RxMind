import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

abstract class MedicationRepositoryBase {
  Future<List<Map<String, dynamic>>> getAll();
  Future<void> replaceAll(List<Map<String, dynamic>> items);
  Future<void> deleteAll();
}

class MedicationRepository implements MedicationRepositoryBase {
  MedicationRepository(this._db);

  final Database _db;

  @override
  Future<List<Map<String, dynamic>>> getAll() async {
    final rows = await _db.query('medications', orderBy: 'updated_at DESC');
    return rows.map(_rowToMap).toList();
  }

  @override
  Future<void> replaceAll(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    batch.delete('medications');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      batch.insert('medications', {
        'id': item['id']?.toString() ?? 'med_$i',
        'name':
            item['name']?.toString() ?? item['medication']?.toString() ?? '',
        'dose': item['dose']?.toString(),
        'frequency': item['frequency']?.toString(),
        'payload_json': jsonEncode(item),
        'updated_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete('medications');
  }

  Map<String, dynamic> _rowToMap(Map<String, Object?> row) {
    if (row['payload_json'] != null) {
      return Map<String, dynamic>.from(
        jsonDecode(row['payload_json'] as String) as Map,
      );
    }
    return {
      'id': row['id'],
      'name': row['name'],
      'dose': row['dose'],
      'frequency': row['frequency'],
    };
  }
}
