import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'master_key_service.dart';
import 'migration_v1.dart';
import 'migration_v2.dart';
import 'schema.dart';

/// Opens and holds the encrypted SQLCipher database singleton.
class SecureDatabase {
  SecureDatabase._();

  static Database? _instance;
  static Database? _testOverride;
  static final MasterKeyService _masterKeyService = MasterKeyService();

  @visibleForTesting
  static void useTestDatabase(Database db) {
    _testOverride = db;
    _instance = db;
  }

  @visibleForTesting
  static Future<void> resetForTest() async {
    await _instance?.close();
    _instance = null;
    _testOverride = null;
  }

  static Future<Database> instance() async {
    if (_testOverride != null && _testOverride!.isOpen) {
      return _testOverride!;
    }
    if (_instance != null && _instance!.isOpen) return _instance!;

    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'rxmind.db');
    _instance = await _masterKeyService.openSecureDatabase(
      path,
      version: Schema.version,
      onCreate: Schema.createAll,
      onUpgrade: MigrationV2.onUpgrade,
    );

    await MigrationV1.runIfNeeded(_instance!);
    await MigrationV2.runIfNeeded(_instance!);
    return _instance!;
  }

  static Future<void> close() async {
    if (_testOverride != null) {
      await _testOverride?.close();
      _testOverride = null;
    }
    await _instance?.close();
    _instance = null;
  }

  static Database? get current => _testOverride ?? _instance;
}
