import 'package:flutter/material.dart';

class AiDisclosureBanner extends StatelessWidget {
  const AiDisclosureBanner({super.key, required this.onAcknowledged});

  final VoidCallback onAcknowledged;

  static const disclosureText =
      'You are interacting with an automated on-device AI system, not a human clinician.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy_outlined,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  disclosureText,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Semantics(
                label: 'I Understand',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onAcknowledged,
                    child: const Text('I Understand'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
