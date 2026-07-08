import 'package:flutter/material.dart';

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
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Important Notice',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  disclaimerText,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Semantics(
                  label: 'I Understand',
                  button: true,
                  child: FilledButton(
                    onPressed: onAcknowledged,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('I Understand'),
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
