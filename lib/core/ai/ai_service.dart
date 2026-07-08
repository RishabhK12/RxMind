import 'package:rxmind_app/core/ai/ai_parser.dart';
import 'package:rxmind_app/core/ai/local_ai_service.dart';
import 'package:rxmind_app/core/ai/rate_limiter.dart';

/// Structured discharge parsing via on-device AI.
class AiService {
  AiService({LocalAiService? localAi}) : _localAi = localAi ?? LocalAiService();

  final LocalAiService _localAi;

  Future<Map<String, dynamic>?> parseDischargeText(String text) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    final result = await _localAi.parseDischargeJson(text);
    if (result == null) return null;
    return AiParser.validateJson(result);
  }
}
