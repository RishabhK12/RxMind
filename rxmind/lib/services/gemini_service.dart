import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<Map<String, dynamic>?> extractTasksAndMeds(
      String dischargeText) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not set.');
    }
    final prompt = _buildPrompt(dischargeText);
    final response = await http.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Gemini returns the text in a nested structure
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null) {
        try {
          return jsonDecode(text);
        } catch (_) {
          // If not valid JSON, return null
          return null;
        }
      }
    }
    return null;
  }

  String _buildPrompt(String summary) {
    return '''You are an AI designed to help patients manage their healthcare after hospital visits. From the discharge summary provided below, extract:
- A clear list of tasks they should complete
- Any medications mentioned
- Ideal times or dates for those tasks or medications
- Make the format compact and machine-parsable.

Output example (JSON):
{
  "tasks": [
    { "title": "Take blood pressure", "time": "8:00 AM daily", "description": "Use the cuff" }
  ],
  "medications": [
    { "name": "Metformin", "dosage": "500mg twice a day" }
  ]
}

Summary:
$summary''';
  }
}
