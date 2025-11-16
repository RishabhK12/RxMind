import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Calls a backend proxy for Gemini requests. The backend holds the API key.
class GeminiBackendClient {
  GeminiBackendClient._();
  static final I = GeminiBackendClient._();

  String get _baseUrl => (dotenv.env['BACKEND_BASE_URL'] ?? '').trim();
  String? get _sharedSecret => dotenv.env['BACKEND_SHARED_SECRET']?.trim();

  /// Simple text generation using a single prompt. Returns the first text.
  Future<String> generateText(
    String prompt, {
    String model = 'gemini-2.0-flash',
    String? systemInstruction,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    int maxOutputTokens = 2048,
  }) async {
    if (_baseUrl.isEmpty) {
      throw StateError('BACKEND_BASE_URL not set. Add it to your .env file.');
    }

    final uri = Uri.parse(_baseUrl.endsWith('/') ? '${_baseUrl}gemini/generate' : '$_baseUrl/gemini/generate');

    final headers = <String, String>{
      'content-type': 'application/json',
    };
    final secret = _sharedSecret;
    if (secret != null && secret.isNotEmpty) {
      headers['x-api-key'] = secret;
    }

    final body = <String, dynamic>{
      'prompt': prompt,
      'model': model,
      'generationConfig': {
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'maxOutputTokens': maxOutputTokens,
      },
    };
    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      // Match direct API client shape (no role field)
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction},
        ],
      };
    }

    final resp = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final text = json['text'] as String?;
        if (text != null && text.isNotEmpty) return text;

        // Fallback parsing if backend returns raw candidates
        final candidates = (json['raw'] as Map<String, dynamic>?)?['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = (candidates.first as Map<String, dynamic>)['content']?['parts'] as List<dynamic>?;
          final sb = StringBuffer();
          if (parts != null) {
            for (final p in parts) {
              final t = (p as Map<String, dynamic>)['text'] as String?;
              if (t != null) sb.writeln(t);
            }
          }
          final result = sb.toString().trim();
          if (result.isNotEmpty) return result;
        }
      } catch (e) {
        if (kDebugMode) {
          print('GeminiBackendClient parse error: $e');
        }
      }

      // If backend didn't include text, return raw body
      return resp.body;
    } else {
      throw HttpExceptionWithBody('Backend error ${resp.statusCode}', resp.body);
    }
  }
}

class HttpExceptionWithBody implements Exception {
  final String message;
  final String body;
  HttpExceptionWithBody(this.message, this.body);
  @override
  String toString() => '$message\n$body';
}
