import 'package:rxmind_app/core/ai/rate_limiter.dart';

/// Thrown when on-device AI is not yet available (Phase 3).
class LocalAiUnavailableException implements Exception {
  LocalAiUnavailableException([this.message = _unavailableMessage]);

  final String message;

  static const String _unavailableMessage =
      'On-device AI is not yet available. Structured parsing will return in a future update.';

  @override
  String toString() => message;
}

/// Local-only AI placeholder. No network calls; no cloud inference.
class LocalAiStub {
  LocalAiStub();

  static const String unavailableMessage =
      LocalAiUnavailableException._unavailableMessage;

  /// Returns a static message — no remote inference.
  Future<String> sendMessage(
    String message, {
    String? systemInstruction,
  }) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    return unavailableMessage;
  }

  /// Returns null — no structured JSON is fabricated without on-device AI.
  Future<Map<String, dynamic>?> parseDischargeText(String text) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    return null;
  }
}
