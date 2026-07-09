import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/local_ai_service.dart';
import 'package:rxmind_app/core/ai/safety_pipeline.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupRxMindTestDatabase();
    LocalAiService.useBackendForTest(_OfflineBackend());
  });

  tearDown(() async {
    LocalAiService.resetBackendForTest();
    await tearDownRxMindTestDatabase();
  });

  test('SafetyPipeline chat works without network', () async {
    final pipeline = SafetyPipeline();
    final result = await pipeline.runChat(
      userMessage: 'What tasks do I have?',
      systemPrompt: 'wellness',
      contextBlock: '',
    );

    expect(result.isEmergency, isFalse);
    expect(result.displayText, isNotEmpty);
  });
}

class _OfflineBackend implements LocalAiBackend {
  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxOutputTokens = 512,
  }) async =>
      'Your wellness tasks are listed in the app dashboard.';

  @override
  Future<Map<String, dynamic>?> parseJson({
    required String systemPrompt,
    required String ocrText,
  }) async =>
      null;
}
