import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest has no READ_CONTACTS or WRITE_CONTACTS', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.toLowerCase(), isNot(contains('read_contacts')));
    expect(manifest.toLowerCase(), isNot(contains('write_contacts')));
  });

  test('iOS Info.plist has no NSContactsUsageDescription', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, isNot(contains('NSContactsUsageDescription')));
  });
}
