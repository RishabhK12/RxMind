import 'package:flutter_test/flutter_test.dart';
import 'package:rxmind_app/core/ai/local_ai_service.dart';
import 'package:rxmind_app/core/ai/model_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers.dart';

class MockAiBackend implements LocalAiBackend {
  int generateCalls = 0;

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxOutputTokens = 512,
  }) async {
    generateCalls++;
    return 'Mock wellness response.';
  }

  @override
  Future<Map<String, dynamic>?> parseJson({
    required String systemPrompt,
    required String ocrText,
  }) async =>
      {'medications': [], 'tasks': []};
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupRxMindTestDatabase();
    LocalAiService.resetBackendForTest();
    ModelLoader.resetForTest();
  });

  tearDown(() async {
    LocalAiService.resetBackendForTest();
    ModelLoader.resetForTest();
    await tearDownRxMindTestDatabase();
  });

  test('generate uses fallback when model not loaded', () async {
    final service = LocalAiService();
    final text = await service.generate(
      systemPrompt: 'test',
      userPrompt: 'hello',
    );
    expect(text, LocalAiUnavailableException.fallbackMessage);
  });

  test('mock backend generate returns response without network', () async {
    LocalAiService.useBackendForTest(MockAiBackend());
    final service = LocalAiService();
    final text = await service.generate(
      systemPrompt: 'sys',
      userPrompt: 'user',
    );
    expect(text, 'Mock wellness response.');
  });

  test('isModelLoaded reflects ModelLoader state', () {
    ModelLoader.setModelReadyForTest(true);
    final service = LocalAiService();
    expect(service.isModelLoaded, isTrue);
  });
}
