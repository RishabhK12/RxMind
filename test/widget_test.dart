import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxmind_app/core/ai/local_ai_stub.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupRxMindTestDatabase();
  });

  tearDown(() async {
    await tearDownRxMindTestDatabase();
  });

  test('LocalAiStub returns static unavailable message', () async {
    final stub = LocalAiStub();
    expect(
      await stub.sendMessage('hello'),
      LocalAiStub.unavailableMessage,
    );
  });

  test('LocalAiStub parseDischargeText returns null', () async {
    final stub = LocalAiStub();
    expect(await stub.parseDischargeText('discharge text'), isNull);
  });
}
