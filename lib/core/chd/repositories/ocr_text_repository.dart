import 'package:sqflite_sqlcipher/sqflite.dart';

class OcrTextRepository {
  OcrTextRepository(this._db);

  final Database _db;

  Future<String?> get() async {
    final rows =
        await _db.query('ocr_text', where: 'id = ?', whereArgs: ['default']);
    if (rows.isEmpty) return null;
    return rows.first['content'] as String?;
  }

  Future<void> save(String? content) async {
    if (content == null || content.isEmpty) {
      await delete();
      return;
    }
    await _db.insert(
      'ocr_text',
      {
        'id': 'default',
        'content': content,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete() async {
    await _db.delete('ocr_text', where: 'id = ?', whereArgs: ['default']);
  }
}
