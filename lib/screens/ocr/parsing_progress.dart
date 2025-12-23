import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/screens/ai/gemini_api_service.dart';

class ParsingProgressScreen extends StatefulWidget {
  const ParsingProgressScreen({super.key});

  @override
  State<ParsingProgressScreen> createState() => _ParsingProgressScreenState();
}

class _ParsingProgressScreenState extends State<ParsingProgressScreen> {
  String? _error;

  String _clipForLog(String s, {int maxChars = 4000}) {
    if (s.length <= maxChars) return s;
    return '${s.substring(0, maxChars)}\n\n[TRUNCATED LOG: ${s.length - maxChars} chars omitted]';
  }

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
      final GeminiApiService geminiService = GeminiApiService();

      // Keep the user message small so more discharge text fits within the
      // on-device model's limited context window.
      const systemInstruction =
          'You extract information from discharge papers and output ONLY JSON. '
          'Do NOT give medical advice, recommendations, or decisions. '
          'Do NOT invent facts. Only use what is explicitly in the text. '
          '\n\nOutput MUST be a single JSON object (not an array) and MUST contain ONLY these top-level keys: '
          'medications, follow_ups, instructions, tasks, warnings, contacts. '
          'Do NOT include person/example fields like id,name,age,gender,email,address,patient,checkup,medical,discharge_text. '
          'Do NOT copy the discharge text into any field. '
          '\n\nCRITICAL: Keep output SMALL and STRICT. '
          'For medications, include ONLY: name, dose, frequency. '
          'Do NOT include any other medication fields (no ids, routes, times, drug_class, drug_brand, URLs, descriptions, etc). '
          '\n\nReturn one JSON object with these keys: medications, follow_ups, instructions, tasks, warnings, contacts. '
          'Each key maps to an array (possibly empty). '
          '\n\nField names per item: '
          'medications(name,dose,frequency); '
          'follow_ups(name,date,hasSpecificDate); '
          'instructions(name); '
          'tasks(title,description,dueDate,dueTime,isRecurring,recurringPattern,recurringInterval,startDate,type,hasSpecificDate); '
          'warnings(text); '
          'contacts(name,phone,address,notes). '
          '\n\nDates: if an exact date/time is not given, use "" and hasSpecificDate=false. '
          '\n\nCategorize: tasks = action + timing; warnings = restrictions/"don\'t"/avoid/monitoring/"if X then Y"; instructions = general guidance without schedule.';

      // Provide an explicit JSON template (minimal) to reduce schema drift.
      const jsonTemplate = '{'
          '"medications":[{"name":"","dose":"","frequency":""}],'
          '"follow_ups":[{"name":"","date":"","hasSpecificDate":false}],'
          '"instructions":[{"name":""}],'
          '"tasks":[{"title":"","description":"","dueDate":"","dueTime":"","isRecurring":false,"recurringPattern":"","recurringInterval":0,"startDate":"","type":"task","hasSpecificDate":false}],'
          '"warnings":[{"text":""}],'
          '"contacts":[{"name":"","phone":"","address":"","notes":""}]'
          '}';

      final userPrompt =
          'DISCHARGE TEXT:\n$reviewedText\n\nReturn JSON only. Must match this template exactly (same keys, no extra fields):\n$jsonTemplate';

      final response = await geminiService.sendMessage(
        userPrompt,
        systemInstruction: systemInstruction,
        // Deterministic decoding for extraction reduces hallucinations.
        temperature: 0.0,
        topK: 1,
        topP: 1.0,
        maxTokens: 512,
      );

      if (kDebugMode) {
        debugPrint('[ParsingProgress] LLM response length: ${response.length}');
        debugPrint(
            '[ParsingProgress] LLM response (clipped):\n${_clipForLog(response)}');
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/parsedSummary',
          arguments: {'parsedJson': response});
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
                    label: 'RxMind logo',
                    child: SvgPicture.asset(
                      'assets/illus/logo.svg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
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
