import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  final String apiKey;
  GeminiApiService({required this.apiKey});

  Future<String> sendMessage(String message) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
    final body = jsonEncode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": message}
          ]
        }
      ]
    });
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    } else {
      String errorMsg = 'Gemini API error: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err['error'] != null && err['error']['message'] != null) {
          errorMsg += '\n${err['error']['message']}';
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }
}
