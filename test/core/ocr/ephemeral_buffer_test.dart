import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ocr/ephemeral_buffer.dart';

void main() {
  test('SecureBytes zeroizes on dispose', () {
    final bytes = SecureBytes(Uint8List.fromList([1, 2, 3, 4]));
    expect(bytes.length, 4);
    bytes.dispose();
    expect(() => bytes.data, throwsStateError);
  });
}
