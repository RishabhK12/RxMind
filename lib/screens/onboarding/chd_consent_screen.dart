import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'package:rxmind_app/widgets/rx_secondary_button.dart';
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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Health Data Consent'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ThemeTokens.spacingLg),
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
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: ThemeTokens.spacingMd),
                        Text(
                          'RxMind collects and stores the following categories of '
                          'Consumer Health Data locally on your device only:',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
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
                        const SizedBox(height: ThemeTokens.spacingMd),
                        Text(
                          'Your data is stored locally on your device. It is not '
                          'uploaded to cloud servers as part of routine app use.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You may withdraw consent at any time by going to '
                          'Settings → Delete All Data, which permanently erases '
                          'all stored health information.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: ThemeTokens.spacingMd),
                RxSecondaryButton(
                  label: 'View Privacy Policy',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyTermsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'I Agree',
                  button: true,
                  child: RxPrimaryButton(
                    label: 'I Agree',
                    onPressed: onConsentGranted,
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
