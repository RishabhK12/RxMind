import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

class LocalStorage {
  static final secureStorage = FlutterSecureStorage();
  static Database? _db;

  static const disclaimerAckKey = 'disclaimer_ack_v1';
  static const chdConsentKey = 'chd_consent_v1';

  static Future<bool> isDisclaimerAcknowledged() async =>
      (await readSecure(disclaimerAckKey)) == 'true';

  static Future<void> setDisclaimerAcknowledged() async =>
      writeSecure(disclaimerAckKey, 'true');

  static Future<bool> hasChdConsent() async =>
      (await readSecure(chdConsentKey)) != null;

  static Future<void> setChdConsent() async => writeSecure(
        chdConsentKey,
        DateTime.now().toUtc().toIso8601String(),
      );

  static Future<void> initDb() async {
    _db = await openDatabase(
      'rxmind.db',
      version: 1,
      onCreate: (db, version) async {
        // Create tables here if needed
        // Example:
        // await db.execute('CREATE TABLE IF NOT EXISTS user_profile (id TEXT PRIMARY KEY, name TEXT, email TEXT, phone TEXT, notes TEXT)');
      },
    );
  }

  // Secure key-value storage
  static Future<void> writeSecure(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  static Future<String?> readSecure(String key) async {
    return await secureStorage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await secureStorage.delete(key: key);
  }

  // Raw DB access for complex objects
  static Database? get db => _db;
}
