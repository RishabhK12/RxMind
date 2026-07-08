import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/core/ai/ai_parser.dart';
import 'package:rxmind_app/core/ai/safety_pipeline.dart';

class ParsingProgressScreen extends StatefulWidget {
  const ParsingProgressScreen({super.key});

  @override
  State<ParsingProgressScreen> createState() => _ParsingProgressScreenState();
}

class _ParsingProgressScreenState extends State<ParsingProgressScreen> {
  String? _error;
  final SafetyPipeline _pipeline = SafetyPipeline();

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
      final result = await _pipeline.runParse(reviewedText);
      final parsed = result.parseJson ?? AiParser.emptySchema();
      final jsonStr = jsonEncode(parsed);
      final hasData = _hasStructuredData(parsed);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/parsedSummary',
        arguments: {'parsedJson': jsonStr},
      );

      if (!mounted) return;
      if (!hasData || result.rateLimited) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Automatic parsing unavailable — review and edit manually',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Parsing failed: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  bool _hasStructuredData(Map<String, dynamic> json) {
    for (final key in ['medications', 'tasks', 'follow_ups', 'instructions']) {
      final list = json[key];
      if (list is List && list.isNotEmpty) return true;
    }
    return false;
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
                children: [
                  SvgPicture.asset(
                    'assets/illus/logo.svg',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(height: 16),
                  if (_error == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Organizing your document...',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
