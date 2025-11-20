import 'dart:convert';
import 'package:rxmind_app/services/ai/gemini_backend_client.dart';
import 'rate_limiter.dart';

/// Legacy AI service refactored to use backend proxy instead of direct API key.
class AiService {
  AiService();

  /// Sends raw text to Gemini via backend, attempting to decode JSON if returned.
  Future<Map<String, dynamic>?> parseDischargeText(String text) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    try {
      final responseText = await GeminiBackendClient.I.generateText(text);
      // Attempt to parse as JSON if model happened to return structured data.
      final trimmed = responseText.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          // Not valid JSON; fall through
        }
      }
      return null; // No structured JSON parsed
    } catch (_) {
      return null;
    }
  }
}
