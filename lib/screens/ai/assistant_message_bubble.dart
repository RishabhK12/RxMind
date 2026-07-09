import 'package:flutter/material.dart';
import 'package:rxmind_app/core/widgets/markdown_text.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.content,
    required this.onReport,
  });

  final String content;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border =
        Theme.of(context).extension<RxMindThemeExtension>()?.border ??
            ThemeTokens.brandBorder;
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark
        ? theme.colorScheme.surface
        : Color.alphaBlend(
            ThemeTokens.violet50.withValues(alpha: 0.65),
            theme.colorScheme.surface,
          );

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: ThemeTokens.spacingXs,
        horizontal: ThemeTokens.spacingMd - 4,
      ),
      padding: const EdgeInsets.all(ThemeTokens.spacingMd - 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownText(data: content, selectable: true),
          const SizedBox(height: ThemeTokens.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('On-device AI', style: theme.textTheme.labelSmall),
              Semantics(
                label: 'Report Content',
                button: true,
                child: TextButton(
                  onPressed: onReport,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ThemeTokens.spacingSm,
                    ),
                    minimumSize: const Size(48, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Report Content',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
