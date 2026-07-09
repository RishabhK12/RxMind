import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyCallTile extends StatelessWidget {
  const EmergencyCallTile({
    super.key,
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: 'Call $number',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: ThemeTokens.spacingSm - 2),
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
          side: BorderSide(color: scheme.error, width: 1.5),
        ),
        child: ListTile(
          leading: Icon(Icons.phone, color: scheme.error),
          title: Text(
            number,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          subtitle: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          trailing: Icon(Icons.call, color: scheme.error),
          onTap: _call,
        ),
      ),
    );
  }
}
