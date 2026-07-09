import 'package:sqflite_sqlcipher/sqflite.dart';

class AppMetadataRepository {
  AppMetadataRepository(this._db);

  final Database _db;

  Future<String?> get(String key) async {
    final rows = await _db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    await _db.insert(
      'app_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String key) async {
    await _db.delete('app_metadata', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> deleteAll() async {
    await _db.delete('app_metadata');
  }
}
