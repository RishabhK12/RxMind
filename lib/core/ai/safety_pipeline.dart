import 'dart:convert';

import 'ai_parser.dart';
import 'local_ai_service.dart';
import 'rate_limiter.dart';
import 'safety_input_filter.dart';
import 'safety_output_filter.dart';
import 'safety_result.dart';
import 'wellness_prompts.dart';

class SafetyPipeline {
  SafetyPipeline({LocalAiService? localAi})
      : _localAi = localAi ?? LocalAiService();

  final LocalAiService _localAi;

  Future<SafetyPipelineResult> runChat({
    required String userMessage,
    required String systemPrompt,
    String contextBlock = '',
  }) async {
    final input = SafetyInputFilter.evaluate(userMessage);
    if (input.isEmergency) {
      return SafetyPipelineResult.emergency(input.primary!);
    }

    if (!await RateLimiter.canMakeRequest()) {
      return SafetyPipelineResult.rateLimited();
    }

    final raw = await _localAi.generate(
      systemPrompt: systemPrompt,
      userPrompt: contextBlock.isEmpty
          ? userMessage
          : '$contextBlock\n\nUSER: $userMessage',
    );

    final output = SafetyOutputFilter.sanitize(raw);
    return SafetyPipelineResult.success(
      displayText: output.displayText,
      sanitizeAction: output.action,
      flags: output.flags,
    );
  }

  Future<SafetyPipelineResult> runParse(String ocrText) async {
    if (!await RateLimiter.canMakeRequest()) {
      return SafetyPipelineResult.rateLimited();
    }

    final raw = await _localAi.generate(
      systemPrompt: WellnessPrompts.parsingOrganizerInstruction,
      userPrompt: ocrText,
      temperature: 0.1,
      maxOutputTokens: 2048,
    );

    final parsed = LocalAiService.tryParseJsonResponse(raw);
    if (parsed == null) {
      final fallback = await _localAi.parseDischargeJson(ocrText);
      if (fallback == null) {
        return SafetyPipelineResult.success(
          displayText: '',
          parseJson: AiParser.emptySchema(),
        );
      }
      return SafetyPipelineResult.success(
        displayText: '',
        parseJson: AiParser.sanitizeParsedJson(
          AiParser.validateJson(fallback),
        ),
      );
    }

    final validated =
        AiParser.sanitizeParsedJson(AiParser.validateJson(parsed));
    final encoded = jsonEncode(validated);
    final output = SafetyOutputFilter.sanitize(encoded);
    if (output.action == OutputSanitizeAction.dropEntire) {
      return SafetyPipelineResult.success(
        displayText: '',
        parseJson: AiParser.emptySchema(),
        sanitizeAction: output.action,
        flags: output.flags,
      );
    }

    try {
      final json = Map<String, dynamic>.from(
        jsonDecode(output.displayText) as Map,
      );
      return SafetyPipelineResult.success(
        displayText: '',
        parseJson: AiParser.sanitizeParsedJson(AiParser.validateJson(json)),
        sanitizeAction: output.action,
        flags: output.flags,
      );
    } catch (_) {
      return SafetyPipelineResult.success(
        displayText: '',
        parseJson: AiParser.emptySchema(),
      );
    }
  }
}
