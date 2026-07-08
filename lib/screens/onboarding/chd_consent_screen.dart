import 'package:flutter/material.dart';
import '../settings/privacy_terms_screen.dart';

/// Standalone Consumer Health Data consent panel — not bundled with Terms.
class ChdConsentScreen extends StatelessWidget {
  const ChdConsentScreen({
    super.key,
    required this.onConsentGranted,
  });

  final VoidCallback onConsentGranted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Health Data Consent'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumer Health Data',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'RxMind collects and stores the following categories of '
                          'Consumer Health Data locally on your device only:',
                        ),
                        const SizedBox(height: 12),
                        const _Bullet(
                          'Discharge documents you scan or import',
                        ),
                        const _Bullet(
                          'Medications, tasks, and follow-up reminders you enter',
                        ),
                        const _Bullet(
                          'Recovery instructions and wellness notes',
                        ),
                        const _Bullet(
                          'Optional profile and scheduling preferences',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your data is stored locally on your device. It is not '
                          'uploaded to cloud servers as part of routine app use.',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You may withdraw consent at any time by going to '
                          'Settings → Delete All Data, which permanently erases '
                          'all stored health information.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyTermsScreen(),
                      ),
                    );
                  },
                  child: const Text('View Privacy Policy'),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'I Agree',
                  button: true,
                  child: FilledButton(
                    onPressed: onConsentGranted,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('I Agree'),
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

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
