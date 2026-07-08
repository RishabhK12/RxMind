import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rxmind_app/core/ai/local_ai_stub.dart';

class ParsingProgressScreen extends StatefulWidget {
  const ParsingProgressScreen({super.key});

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
      final stub = LocalAiStub();
      await stub.sendMessage(reviewedText);

      const emptyJson =
          '{"medications":[],"tasks":[],"follow_ups":[],"instructions":[],"warnings":[]}';

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/parsedSummary',
          arguments: {'parsedJson': emptyJson});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Automatic parsing unavailable — review and edit manually',
          ),
        ),
      );
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
