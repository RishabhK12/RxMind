import 'package:flutter/material.dart';

import '../theme/theme_tokens.dart';

enum RxStatusKind { success, warning, info, error }

class RxStatusChip extends StatelessWidget {
  const RxStatusChip({
    super.key,
    required this.label,
    this.kind = RxStatusKind.info,
  });

  final String label;
  final RxStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    late final Color bg;
    late final Color fg;

    switch (kind) {
      case RxStatusKind.success:
        bg = isDark
            ? ThemeTokens.darkSuccess.withValues(alpha: 0.2)
            : ThemeTokens.emerald50;
        fg = isDark ? ThemeTokens.darkSuccess : ThemeTokens.brandEmerald;
      case RxStatusKind.warning:
        bg = isDark
            ? ThemeTokens.darkWarning.withValues(alpha: 0.2)
            : ThemeTokens.amber50;
        fg = ThemeTokens.brandFg;
      case RxStatusKind.info:
        bg = isDark
            ? ThemeTokens.darkInfo.withValues(alpha: 0.2)
            : ThemeTokens.blue50;
        fg = isDark ? ThemeTokens.darkInfo : ThemeTokens.brandBlue;
      case RxStatusKind.error:
        bg = isDark
            ? theme.colorScheme.error.withValues(alpha: 0.2)
            : ThemeTokens.rose50;
        fg = theme.colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ThemeTokens.radiusPill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
