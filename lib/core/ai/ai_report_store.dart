import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../storage/sqlcipher_database.dart';
import 'report_reason.dart';

class AiReportStore {
  AiReportStore(this._db);

  final Database _db;

  static Future<AiReportStore> instance() async {
    return AiReportStore(await SecureDatabase.instance());
  }

  Future<void> insert({
    required String messageId,
    required String messageHash,
    required ReportReason reason,
    String? note,
    DateTime? createdAt,
  }) async {
    await _db.insert('ai_reports', {
      'id': 'report_${DateTime.now().microsecondsSinceEpoch}',
      'message_id': messageId,
      'message_hash': messageHash,
      'reason_code': reason.code,
      'note': note,
      'created_at':
          (createdAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch,
    });
  }

  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as c FROM ai_reports');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static String hashContent(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }
}
