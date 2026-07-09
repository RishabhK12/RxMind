import 'package:flutter/material.dart';

import '../theme/theme_tokens.dart';
import 'rx_primary_button.dart';

class RxEmptyState extends StatelessWidget {
  const RxEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.wellColor,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? wellColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final well = wellColor ?? ThemeTokens.blue50;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? ThemeTokens.darkMuted
                      : well,
                  borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
                ),
                child: Icon(icon, size: 36, color: theme.colorScheme.primary),
              ),
            const SizedBox(height: ThemeTokens.spacingMd),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: ThemeTokens.spacingSm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ThemeTokens.spacingLg),
              RxPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
