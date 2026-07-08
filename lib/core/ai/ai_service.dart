import 'package:rxmind_app/core/ai/local_ai_stub.dart';
import 'rate_limiter.dart';

/// Legacy AI service refactored to local-only stub (Phase 3 will add real inference).
class AiService {
  AiService() : _stub = LocalAiStub();

  final LocalAiStub _stub;

  /// Attempts structured parse via on-device AI; returns null until Phase 3.
  Future<Map<String, dynamic>?> parseDischargeText(String text) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    return _stub.parseDischargeText(text);
  }
}
