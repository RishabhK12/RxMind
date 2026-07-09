import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Renders markdown using the ambient [ThemeData.textTheme] / colorScheme.
class MarkdownText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final bool selectable;

  const MarkdownText({
    super.key,
    required this.data,
    this.style,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium;

    return MarkdownBody(
      data: _cleanMarkdown(data),
      selectable: selectable,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        h1: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h2: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h3: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        h4: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        h5: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        h6: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        strong: baseStyle?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        em: baseStyle?.copyWith(
          fontStyle: FontStyle.italic,
        ),
        listBullet: baseStyle?.copyWith(
          color: theme.colorScheme.primary,
        ),
        code: baseStyle?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        blockquote: baseStyle?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Clean up common markdown fence artifacts from model output.
  String _cleanMarkdown(String text) {
    String cleaned = text.trim();

    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.length > 2) {
        cleaned = lines.sublist(1, lines.length - 1).join('\n');
      }
    }

    // Remove trailing code block marker
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }

    return cleaned;
  }
}
