import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/core/ai/ai_parser.dart';
import 'package:rxmind_app/core/ai/safety_pipeline.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Automatic parsing unavailable — review and edit manually',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onInverseSurface,
              ),
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
    final ext = RxMindThemeExtension.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.scrim.withValues(alpha: 0.5),
      body: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            label: _error == null ? 'Parsing in progress' : 'Parsing error',
            liveRegion: true,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(ThemeTokens.spacingLg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
                border: Border.all(color: ext.border),
                boxShadow: ext.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(ThemeTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? ThemeTokens.darkMuted
                          : ThemeTokens.emerald50,
                      borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
                    ),
                    child: SvgPicture.asset(
                      'assets/illus/logo.svg',
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const SizedBox(height: ThemeTokens.spacingMd),
                  if (_error == null) ...[
                    CircularProgressIndicator(
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: ThemeTokens.spacingMd),
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
