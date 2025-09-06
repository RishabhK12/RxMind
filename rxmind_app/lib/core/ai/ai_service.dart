import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  final String apiKey;
  AiService([String? key]) : apiKey = key ?? dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<Map<String, dynamic>?> parseDischargeText(String text) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');
    final prompt = {
      'contents': [
        {
          'parts': [
            {'text': text}
          ]
        }
      ]
    };
    final response = await http.post(url,
        body: jsonEncode(prompt),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
