import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'sqlcipher_database.dart';

class LocalStorage {
  static const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

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
    await SecureDatabase.instance();
  }

  static Future<void> writeSecure(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  static Future<String?> readSecure(String key) async {
    return secureStorage.read(key: key);
  }

  static Future<void> deleteSecure(String key) async {
    await secureStorage.delete(key: key);
  }

  static Database? get db => SecureDatabase.current;
}
