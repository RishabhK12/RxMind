import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/storage/schema.dart';

void main() {
  test('Schema version is positive', () {
    expect(Schema.version, greaterThan(0));
  });
}
