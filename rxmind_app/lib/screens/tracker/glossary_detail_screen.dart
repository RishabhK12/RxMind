import 'package:flutter/material.dart';
import '../ai/gemini_api_service.dart';
import '../../gemini_api_key.dart';
import '../../core/widgets/markdown_text.dart';

class GlossaryDetailScreen extends StatefulWidget {
  final String term;
  const GlossaryDetailScreen({super.key, required this.term});

  @override
  State<GlossaryDetailScreen> createState() => _GlossaryDetailScreenState();
}

class _GlossaryDetailScreenState extends State<GlossaryDetailScreen> {
  late final GeminiApiService _geminiApi =
      GeminiApiService(apiKey: geminiApiKey);
  String? definition;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDefinition();
  }

  Future<void> fetchDefinition() async {
    // Use Gemini API with a highly specific prompt for a patient-friendly, detailed, structured definition. No preamble, no confirmation text.
    final prompt = '''
You are a medical glossary assistant. For the term "${widget.term}", provide ONLY the following, in this order, with clear section headers:

1. A concise, patient-friendly definition (1-2 sentences).
2. A "Why it matters" section (1-2 sentences on why a patient should care about this term).
3. A "Key facts" section (3-5 bullet points with the most important facts, risks, or uses).
4. A "Common questions" section (2-3 short Q&A pairs relevant to patients).

Do NOT include any preamble, confirmation, or closing text. Do NOT say things like "Sure, here is..." or "Okay, I will...". Only output the sections above, clearly formatted for a patient.
''';
    try {
      final response = await _geminiApi.sendMessage(prompt);
      // Remove any preamble/confirmation text if present (just in case)
      final cleaned = _stripPreamble(response);
      setState(() {
        definition = cleaned;
        loading = false;
      });
    } catch (e) {
      setState(() {
        definition = 'Unable to fetch information.';
        loading = false;
      });
    }
  }

  String _stripPreamble(String text) {
    // Remove common Gemini preambles, confirmation, or closing lines
    final patterns = [
      RegExp(
          r'^(Okay|Sure|Here is|Here are|I will|Of course|Certainly)[^\n]*[\n\r]+',
          caseSensitive: false,
          multiLine: true),
      RegExp(r'^(\s*\*\*.*?\*\*\s*)',
          caseSensitive: false, multiLine: true), // Markdown bold preambles
    ];
    String cleaned = text.trim();
    for (final pat in patterns) {
      cleaned = cleaned.replaceAll(pat, '');
    }
    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.term),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MarkdownText(data: definition ?? ''),
                ),
              ),
      ),
    );
  }
}
