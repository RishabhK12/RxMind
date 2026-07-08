import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'database_key_exception.dart';
import 'schema.dart';

class MasterKeyService {
  MasterKeyService({MethodChannel? channel, FlutterSecureStorage? storage})
      : _channel = channel ?? const MethodChannel('rxmind/crypto'),
        _fallbackStorage = storage ?? const FlutterSecureStorage();

  static const _fallbackSaltKey = 'rxmind_fallback_salt_v1';
  static const _fallbackDekKey = 'rxmind_fallback_dek_v1';
  static const pbkdf2Iterations = 100000;

  final MethodChannel _channel;
  final FlutterSecureStorage _fallbackStorage;
  static final Map<String, String> _memoryFallbackStore = {};

  /// Returns the opaque hardware key alias; never exposes raw key bytes.
  Future<String> getMasterKeyAlias() async {
    final alias = await _channel.invokeMethod<String>('getMasterKeyAlias');
    return alias ?? 'rxmind_mk_v1';
  }

  Future<bool> provisionMasterKey() async {
    try {
      final ok = await _channel.invokeMethod<bool>('provisionMasterKey');
      if (ok == true) return true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('MasterKeyService: native provision failed: ${e.message}');
      }
    } on MissingPluginException {
      // Desktop / test VM — use secure-storage fallback.
    }
    return _provisionFallbackKey();
  }

  Future<Uint8List> deriveDatabaseKey() async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('deriveDatabaseKey');
      if (result != null && result.isNotEmpty) {
        return Uint8List.fromList(result);
      }
    } on PlatformException catch (e) {
      if (e.code == 'DATABASE_KEY_UNAVAILABLE') {
        throw DatabaseKeyException(e.message ?? 'Master key unavailable');
      }
      if (kDebugMode) {
        debugPrint('MasterKeyService: derive failed: ${e.message}');
      }
    } on MissingPluginException {
      // Fallback below.
    }
    return _deriveFallbackDatabaseKey();
  }

  Future<Database> openSecureDatabase(
    String path, {
    int version = Schema.version,
    Future<void> Function(Database db, int version)? onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    await provisionMasterKey();
    final passphrase = await deriveDatabaseKey();
    try {
      return await openDatabase(
        path,
        password: String.fromCharCodes(passphrase),
        version: version,
        onCreate: onCreate ?? Schema.createAll,
        onUpgrade: onUpgrade,
      );
    } finally {
      for (var i = 0; i < passphrase.length; i++) {
        passphrase[i] = 0;
      }
    }
  }

  Future<bool> _provisionFallbackKey() async {
    try {
      var saltB64 = await _fallbackStorage.read(key: _fallbackSaltKey);
      var dekB64 = await _fallbackStorage.read(key: _fallbackDekKey);
      if (saltB64 == null || dekB64 == null) {
        final salt = _randomBytes(32);
        final dek = _randomBytes(32);
        saltB64 = _bytesToB64(salt);
        dekB64 = _bytesToB64(dek);
        await _fallbackStorage.write(key: _fallbackSaltKey, value: saltB64);
        await _fallbackStorage.write(key: _fallbackDekKey, value: dekB64);
        _memoryFallbackStore[_fallbackSaltKey] = saltB64;
        _memoryFallbackStore[_fallbackDekKey] = dekB64;
      }
      return true;
    } catch (_) {
      if (!_memoryFallbackStore.containsKey(_fallbackSaltKey)) {
        _memoryFallbackStore[_fallbackSaltKey] = _bytesToB64(_randomBytes(32));
        _memoryFallbackStore[_fallbackDekKey] = _bytesToB64(_randomBytes(32));
      }
      return true;
    }
  }

  Future<Uint8List> _deriveFallbackDatabaseKey() async {
    try {
      final saltB64 = await _fallbackStorage.read(key: _fallbackSaltKey);
      final dekB64 = await _fallbackStorage.read(key: _fallbackDekKey);
      if (saltB64 != null && dekB64 != null) {
        return _pbkdf2(_b64ToBytes(dekB64), _b64ToBytes(saltB64), pbkdf2Iterations, 32);
      }
    } catch (_) {}
    final saltB64 = _memoryFallbackStore[_fallbackSaltKey];
    final dekB64 = _memoryFallbackStore[_fallbackDekKey];
    if (saltB64 == null || dekB64 == null) {
      throw DatabaseKeyException('Fallback key not provisioned');
    }
    return _pbkdf2(_b64ToBytes(dekB64), _b64ToBytes(saltB64), pbkdf2Iterations, 32);
  }

  static Uint8List _pbkdf2(
    Uint8List password,
    Uint8List salt,
    int iterations,
    int length,
  ) {
    final hmac = Hmac(sha256, password);
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(block);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return Uint8List.fromList(result.sublist(0, length));
  }

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = DateTime.now().microsecondsSinceEpoch.hashCode & 0xFF;
    }
    final extra = sha256.convert(bytes).bytes;
    return Uint8List.fromList(extra.sublist(0, length));
  }

  static String _bytesToB64(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _b64ToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
