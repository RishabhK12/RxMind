import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/storage/database_key_exception.dart';
import 'package:rxmind_app/core/storage/master_key_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MasterKeyService', () {
    test('provisionMasterKey uses fallback when channel missing', () async {
      final service = MasterKeyService(channel: _FailingChannel());
      expect(await service.provisionMasterKey(), isTrue);
    });

    test('deriveDatabaseKey returns 32 bytes via fallback', () async {
      final service = MasterKeyService(channel: _FailingChannel());
      await service.provisionMasterKey();
      final key = await service.deriveDatabaseKey();
      expect(key.length, 32);
    });

    test('getMasterKeyAlias returns default when channel missing', () async {
      final service = MasterKeyService(channel: _FailingChannel());
      expect(await service.getMasterKeyAlias(), 'rxmind_mk_v1');
    });
  });
}

class _FailingChannel extends MethodChannel {
  _FailingChannel() : super('rxmind/crypto');

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    if (method == 'getMasterKeyAlias') return 'rxmind_mk_v1' as T;
    throw MissingPluginException('not available');
  }
}
