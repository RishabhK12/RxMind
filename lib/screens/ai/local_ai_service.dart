import 'package:rxmind_app/core/ai/local_ai_stub.dart';

/// Thin facade over [LocalAiStub] for screen-layer AI calls.
/// Replaces the former cloud Gemini proxy — no network inference.
class LocalAiService {
  LocalAiService() : _stub = LocalAiStub();

  final LocalAiStub _stub;

  /// Returns the on-device AI placeholder message until Phase 3.
  Future<String> sendMessage(
    String message, {
    String? systemInstruction,
  }) =>
      _stub.sendMessage(message, systemInstruction: systemInstruction);
}
