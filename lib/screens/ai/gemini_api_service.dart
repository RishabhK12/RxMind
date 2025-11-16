import 'package:rxmind_app/services/ai/gemini_backend_client.dart';

/// Updated Gemini API service that delegates all requests to the backend proxy.
/// The mobile app no longer holds or transmits the Gemini API key directly.
class GeminiApiService {
  GeminiApiService();

  /// Sends a prompt to the backend which forwards to Gemini.
  /// Returns the generated text (may be empty string on failure).
  Future<String> sendMessage(String message, {String? systemInstruction}) async {
    try {
      final text = await GeminiBackendClient.I.generateText(
        message,
        systemInstruction: systemInstruction,
        // Preserve prior defaults
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      );
      return text.trim();
    } catch (e) {
      // Bubble up as Exception to match previous behavior
      throw Exception('Gemini backend error: $e');
    }
  }
}
