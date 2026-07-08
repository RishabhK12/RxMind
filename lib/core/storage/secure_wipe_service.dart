import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';
import '../chd/repositories/app_metadata_repository.dart';
import 'sqlcipher_database.dart';

/// Multi-pass cryptographic wipe for Erase All My Data.
class SecureWipeService {
  static const _channel = MethodChannel('rxmind/crypto');

  static Future<void> wipeAll() async {
    final notificationService = NotificationService();
    await notificationService.cancelAllNotifications();

    await SecureDatabase.close();

    try {
      await _channel.invokeMethod('wipeAll');
    } on PlatformException {
      await _wipeDatabaseFilesFallback();
    } on MissingPluginException {
      await _wipeDatabaseFilesFallback();
    }

    await const FlutterSecureStorage().deleteAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await _wipeTempDirectories();
  }

  static Future<void> _wipeDatabaseFilesFallback() async {
    final dir = await getApplicationSupportDirectory();
    for (final name in ['rxmind.db', 'rxmind.db-wal', 'rxmind.db-shm']) {
      final file = File(p.join(dir.path, name));
      if (await file.exists()) {
        await _secureDeleteFile(file);
      }
    }
  }

  static Future<void> _secureDeleteFile(File file) async {
    if (!await file.exists()) return;
    final length = await file.length();
    if (length == 0) {
      await file.delete();
      return;
    }
    final raf = await file.open(mode: FileMode.write);
    try {
      await raf.setPosition(0);
      await raf.writeFrom(List.filled(length, 0));
      await raf.flush();
      await raf.setPosition(0);
      await raf.writeFrom(List.filled(length, 0xFF));
      await raf.flush();
      await raf.setPosition(0);
      await raf.writeFrom(
        List.generate(length, (i) => (i * 37 + 91) & 0xFF),
      );
      await raf.flush();
    } finally {
      await raf.close();
    }
    await file.delete();
  }

  static Future<void> _wipeTempDirectories() async {
    try {
      final temp = await getTemporaryDirectory();
      if (await temp.exists()) {
        await for (final entity in temp.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static Future<bool> isDischargeUploaded() async {
    try {
      final db = await SecureDatabase.instance();
      final meta = AppMetadataRepository(db);
      return await meta.get('discharge_uploaded') == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setDischargeUploaded(bool value) async {
    final db = await SecureDatabase.instance();
    final meta = AppMetadataRepository(db);
    if (value) {
      await meta.set('discharge_uploaded', 'true');
    } else {
      await meta.delete('discharge_uploaded');
    }
  }
}
