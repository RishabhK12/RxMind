import 'package:rxmind_app/services/ai/local_llm_service.dart';

/// AI service that uses a local on-device LLM for complete privacy.
/// All inference runs locally - no data is sent to external servers.
class GeminiApiService {
  GeminiApiService();

  final LocalLlmService _localLlm = LocalLlmService.I;

  /// Sends a prompt to the local LLM.
  /// Returns the generated text (may be empty string on failure).
  Future<String> sendMessage(
    String message, {
    String? systemInstruction,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    int maxTokens = 1024,
  }) async {
    try {
      final text = await _localLlm.generateText(
        message,
        systemInstruction: systemInstruction,
        temperature: temperature,
        topK: topK,
        topP: topP,
        maxTokens: maxTokens,
      );
      return text.trim();
    } catch (e) {
      throw Exception('AI error: $e');
    }
  }

  /// Check if the AI model is ready
  Future<bool> isModelReady() async {
    return _localLlm.isModelLoaded;
  }

  /// Initialize the AI model with progress callback
  Future<bool> initialize(
      {Function(double progress, String status)? onProgress}) async {
    return await _localLlm.initialize(onProgress: onProgress);
  }

  /// Check if model is downloaded
  Future<bool> isModelDownloaded() async {
    return await _localLlm.isModelDownloaded();
  }
}
