import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'model_loader.dart';
import 'rate_limiter.dart';

/// Thrown when on-device AI cannot serve a request.
class LocalAiUnavailableException implements Exception {
  LocalAiUnavailableException([this.message = fallbackMessage]);

  final String message;

  static const String fallbackMessage =
      'On-device AI is temporarily unavailable. '
      'Please refer to your discharge documents or contact your care team.';

  @override
  String toString() => message;
}

/// Injectable backend for tests and platform-specific Gemma runtime.
abstract class LocalAiBackend {
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature,
    int maxOutputTokens,
  });

  Future<Map<String, dynamic>?> parseJson({
    required String systemPrompt,
    required String ocrText,
  });
}

class FallbackAiBackend implements LocalAiBackend {
  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxOutputTokens = 512,
  }) async {
    return LocalAiUnavailableException.fallbackMessage;
  }

  @override
  Future<Map<String, dynamic>?> parseJson({
    required String systemPrompt,
    required String ocrText,
  }) async =>
      null;
}

class GemmaAiBackend implements LocalAiBackend {
  GemmaAiBackend(this._inner);

  final LocalAiBackend _inner;

  @override
  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxOutputTokens = 512,
  }) {
    if (!ModelLoader.isModelReady) {
      return Future.value(LocalAiUnavailableException.fallbackMessage);
    }
    return _inner.generate(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  @override
  Future<Map<String, dynamic>?> parseJson({
    required String systemPrompt,
    required String ocrText,
  }) {
    if (!ModelLoader.isModelReady) return Future.value(null);
    return _inner.parseJson(systemPrompt: systemPrompt, ocrText: ocrText);
  }
}

/// On-device AI service — zero network calls.
class LocalAiService {
  LocalAiService({LocalAiBackend? backend})
      : _backend = backend ?? _defaultBackend();

  static LocalAiBackend? _testBackend;

  final LocalAiBackend _backend;

  static LocalAiBackend _defaultBackend() {
    if (_testBackend != null) return _testBackend!;
    return GemmaAiBackend(FallbackAiBackend());
  }

  @visibleForTesting
  static void useBackendForTest(LocalAiBackend backend) {
    _testBackend = backend;
  }

  @visibleForTesting
  static void resetBackendForTest() {
    _testBackend = null;
  }

  bool get isModelLoaded => ModelLoader.isModelReady;

  Future<void> ensureInitialized() => ModelLoader.initialize();

  Future<String> generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.2,
    int maxOutputTokens = 512,
  }) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    await ensureInitialized();
    return _backend.generate(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  /// Legacy screen API — maps to [generate].
  Future<String> sendMessage(
    String message, {
    String? systemInstruction,
    String contextBlock = '',
  }) =>
      generate(
        systemPrompt: systemInstruction ?? '',
        userPrompt:
            contextBlock.isEmpty ? message : '$contextBlock\n\nUSER: $message',
      );

  Future<Map<String, dynamic>?> parseDischargeJson(String ocrText) async {
    if (!await RateLimiter.canMakeRequest()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }
    await ensureInitialized();
    return _backend.parseJson(
      systemPrompt: '',
      ocrText: ocrText,
    );
  }

  static Map<String, dynamic>? tryParseJsonResponse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      return Map<String, dynamic>.from(
        jsonDecode(trimmed.substring(start, end + 1)) as Map,
      );
    } catch (_) {
      return null;
    }
  }
}
