import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:rxmind_app/config/backend_config.dart';

/// Calls a backend proxy for Gemini requests. The backend holds the API key.
class GeminiBackendClient {
  GeminiBackendClient._();
  static final I = GeminiBackendClient._();

  String? get _envBaseUrl {
    final envUrl = dotenv.env['BACKEND_BASE_URL']?.trim();
    if (envUrl == null || envUrl.isEmpty) return null;
    return envUrl;
  }

  String get _fallbackBaseUrl => BackendConfig.backendBaseUrl.trim();

  String? get _sharedSecret {
    final envSecret = dotenv.env['BACKEND_SHARED_SECRET']?.trim();
    if (envSecret != null && envSecret.isNotEmpty) return envSecret;
    final fallbackSecret = BackendConfig.backendSharedSecret.trim();
    return fallbackSecret.isEmpty ? null : fallbackSecret;
  }

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
    final envUrl = _envBaseUrl;
    final fallbackUrl = _fallbackBaseUrl;

    Future<String> attempt(String baseUrl) async {
      final normalized = _normalizeBaseUrl(baseUrl);
      final uri = _buildGenerateUri(normalized);

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
          final candidates = (json['raw']
              as Map<String, dynamic>?)?['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = (candidates.first as Map<String, dynamic>)['content']
                ?['parts'] as List<dynamic>?;
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
        throw HttpExceptionWithBody(
            'Backend error ${resp.statusCode}', resp.body);
      }
    }

    try {
      return await attempt(envUrl ?? fallbackUrl);
    } on SocketException catch (e) {
      if (envUrl != null && envUrl != fallbackUrl) {
        if (kDebugMode) {
          debugPrint(
              '[GeminiBackendClient] Host lookup failed for BACKEND_BASE_URL "$envUrl". Falling back to bundled worker. Error: $e');
        }
        return await attempt(fallbackUrl);
      }
      rethrow;
    } on http.ClientException catch (e) {
      if (envUrl != null && envUrl != fallbackUrl) {
        if (kDebugMode) {
          debugPrint(
              '[GeminiBackendClient] HTTP client failed for BACKEND_BASE_URL "$envUrl" (${e.message}). Falling back to bundled worker.');
        }
        return await attempt(fallbackUrl);
      }
      rethrow;
    } on FormatException catch (e) {
      if (envUrl != null && envUrl != fallbackUrl) {
        if (kDebugMode) {
          debugPrint(
              '[GeminiBackendClient] BACKEND_BASE_URL "$envUrl" is invalid. Using bundled worker instead. Error: $e');
        }
        return await attempt(fallbackUrl);
      }
      rethrow;
    } on StateError catch (e) {
      if (envUrl != null && envUrl != fallbackUrl) {
        if (kDebugMode) {
          debugPrint(
              '[GeminiBackendClient] BACKEND_BASE_URL "$envUrl" rejected: ${e.message}. Using bundled worker instead.');
        }
        return await attempt(fallbackUrl);
      }
      rethrow;
    }
  }

  String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw StateError('Backend base URL may not be empty.');
    }
    if (!trimmed.toLowerCase().startsWith('https://')) {
      throw StateError(
          'BACKEND_BASE_URL must use https:// for transport security.');
    }
    return trimmed;
  }

  Uri _buildGenerateUri(String baseUrl) {
    return Uri.parse(baseUrl.endsWith('/')
        ? '$baseUrl' 'gemini/generate'
        : '$baseUrl/gemini/generate');
  }
}

class HttpExceptionWithBody implements Exception {
  final String message;
  final String body;
  HttpExceptionWithBody(this.message, this.body);
  @override
  String toString() => '$message\n$body';
}
