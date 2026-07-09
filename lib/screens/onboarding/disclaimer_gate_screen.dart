import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';

/// Mandatory non-medical-device disclaimer shown before any health data entry.
class DisclaimerGateScreen extends StatelessWidget {
  const DisclaimerGateScreen({
    super.key,
    required this.onAcknowledged,
  });

  static const disclaimerText =
      'This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a licensed healthcare professional for medical advice.';

  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ThemeTokens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: ThemeTokens.spacingLg),
                Text(
                  'Important Notice',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ThemeTokens.spacingLg),
                Text(
                  disclaimerText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Semantics(
                  label: 'I Understand',
                  button: true,
                  child: RxPrimaryButton(
                    label: 'I Understand',
                    onPressed: onAcknowledged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
