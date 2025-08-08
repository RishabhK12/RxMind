import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ParsingProgressScreen extends StatefulWidget {
  const ParsingProgressScreen({Key? key}) : super(key: key);

  @override
  State<ParsingProgressScreen> createState() => _ParsingProgressScreenState();
}

class _ParsingProgressScreenState extends State<ParsingProgressScreen> {
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parseText();
  }

  Future<void> _parseText() async {
    final reviewedText = ModalRoute.of(context)?.settings.arguments as String?;
    if (reviewedText == null) {
      setState(() => _error = 'No text provided.');
      return;
    }
    try {
      const apiKey =
          'YOUR_GEMINI_API_KEY_HERE'; // <-- Replace with your Gemini API key
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Parse the following hospital discharge text into structured JSON with medications, follow-ups, and instructions: $reviewedText"
              }
            ]
          }
        ]
      });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Gemini returns the result in data['candidates'][0]['content']['parts'][0]['text']
        final parsedJson =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/parsedSummary',
            arguments: {'parsedJson': parsedJson});
      } else {
        setState(() => _error = 'Gemini API error: ${response.statusCode}');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Parsing failed: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            label: _error == null ? 'Parsing in progress' : 'Parsing error',
            liveRegion: true,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Progress indicator',
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor:
                          AlwaysStoppedAnimation(theme.colorScheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? 'Parsing Your Discharge Text...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few seconds. Please wait...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
