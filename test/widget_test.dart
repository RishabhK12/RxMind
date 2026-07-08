import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/local_ai_service.dart';
import 'package:rxmind_app/core/ai/safety_input_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('LocalAiService fallback when model unavailable', () async {
    final service = LocalAiService();
    expect(
      await service.generate(systemPrompt: 's', userPrompt: 'hello'),
      LocalAiUnavailableException.fallbackMessage,
    );
  });

  test('SafetyInputFilter blocks crisis language', () {
    final result = SafetyInputFilter.evaluate('I want to kill myself');
    expect(result.isEmergency, isTrue);
  });
}
