import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureDatabase', () {
    test('open success placeholder', () {}, skip: 'Requires SQLCipher native libs');
    test('DatabaseKeyException on locked key', () {}, skip: true);
    test('hex dump not plaintext', () {}, skip: true);
  });
}
