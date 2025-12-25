import 'dart:convert';
import 'package:rxmind_app/services/ai/local_llm_service.dart';

/// AI service for parsing discharge text using local on-device LLM.
/// All data stays on device for complete privacy.
class AiService {
  AiService();

  final LocalLlmService _localLlm = LocalLlmService.I;

  /// Sends raw text to local LLM, attempting to decode JSON if returned.
  Future<Map<String, dynamic>?> parseDischargeText(String text) async {
    try {
      final responseText = await _localLlm.generateText(text);
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
