import 'package:flutter/material.dart';
import 'package:rxmind_app/core/widgets/markdown_text.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownText(data: content, selectable: true),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('On-device AI', style: theme.textTheme.labelSmall),
              Semantics(
                label: 'Report Output',
                button: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 20),
                    tooltip: 'Report Output',
                    onPressed: onReport,
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
