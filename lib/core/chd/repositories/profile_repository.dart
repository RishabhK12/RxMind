import 'dart:convert';

import 'package:sqflite_sqlcipher/sqflite.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final Database _db;

  Future<Map<String, dynamic>> get() async {
    final rows = await _db.query('profile', where: 'id = ?', whereArgs: ['default']);
    if (rows.isEmpty) return {};
    final row = rows.first;
    return {
      'name': row['name'],
      'height': row['height'],
      'weight': row['weight'],
      'age': row['age'],
      'sex': row['sex'],
      'bedtime': row['bedtime'],
      'wakeTime': row['wake_time'],
    };
  }

  Future<void> upsert(Map<String, dynamic> data) async {
    await _db.insert(
      'profile',
      {
        'id': 'default',
        'name': data['name'],
        'height': data['height'],
        'weight': data['weight'],
        'age': data['age'],
        'sex': data['sex'],
        'bedtime': data['bedtime'],
        'wake_time': data['wakeTime'] ?? data['wake_time'],
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAll() async {
    await _db.delete('profile');
  }
}
