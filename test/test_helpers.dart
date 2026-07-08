import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rxmind_app/core/storage/schema.dart';
import 'package:rxmind_app/core/storage/sqlcipher_database.dart';

bool _initialized = false;

Future<void> setupRxMindTestDatabase() async {
  if (!_initialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: Schema.version,
    onCreate: Schema.createAll,
  );
  SecureDatabase.useTestDatabase(db);
}

Future<void> tearDownRxMindTestDatabase() async {
  await SecureDatabase.resetForTest();
}
