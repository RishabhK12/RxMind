import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_app_bar_logo.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  static const _privacyPolicy = '''
Last Updated: July 8, 2026

rxmind is a personal recovery organizer. This Privacy Policy explains how we handle your data when you use our mobile application.

What Information We Collect

Information You Provide
You may provide photos or PDFs of discharge papers, manually entered medications, schedules, tasks, follow-up appointments, notes, reminders, and questions for on-device wellness clarification. This may include health information.

Automatically Collected Data
rxmind does not automatically collect or upload health-related information. We do not use advertising SDKs or analytics on screens that display your health logs.

No Account Required
You may use rxmind without creating an account.

How Your Data Is Stored

Local-Only Storage
All sensitive data, including medications, tasks, appointments, reminders, and extracted text, is stored locally on your device using secure on-device storage. No protected health information is stored on external servers.

How Your Data Is Used

We use your information to extract text from discharge papers using on-device OCR, organize tasks and medications, create reminders, and generate summaries or reports you choose to export. We do not sell your data, share your health information with advertisers, or use your data for marketing purposes.

On-Device AI
Optional on-device AI features (when available) run locally on your phone. Health data is not transmitted to cloud AI services as part of routine app operation.

User Controls

You may delete all app data via Settings → Delete All Data, remove individual entries, export your data, or uninstall the app to remove all local data.

Children's Privacy

rxmind is not intended for children under 13.

Security Measures

We use secure local storage technologies and device-level protections. While no system is entirely secure, we take reasonable steps to safeguard your information.

Contact Us

privacy@rxmind.app
''';

  static const _termsOfService = '''
Last Updated: July 8, 2026

These Terms of Service govern your use of the rxmind application.

Purpose of the App

rxmind helps users manage post-discharge recovery by scanning documents, organizing tasks and medications, providing reminders, and offering on-device wellness clarification.
rxmind does not replace professional healthcare, suggest medication changes, make treatment decisions, or handle emergencies.
You must consult your healthcare provider for medical needs.

License to Use the App

We grant you a personal, non-transferable, revocable license to use the app. You may not reverse engineer the app, interfere with its operation, misuse AI features, upload protected health information of others without permission, or bypass safety features.

Wellness Clarification Disclaimer

On-device wellness features clarify information you provide. They do not provide clinical guidance, evaluate prescriptions, or ensure accuracy. You must verify all health information with a licensed professional.

OCR and Extraction Limitations

OCR accuracy depends on image quality. Extracted data is not guaranteed to be accurate, and you must confirm all information manually.

Limitations of Liability

rxmind is provided "as is." We are not liable for medical decisions you make, incorrect OCR results, missed reminders, or data loss on your device.

Privacy Policy

Your use of the app is governed by the Privacy Policy above.
''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Privacy Policy & Terms of Service',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ThemeTokens.spacingMd),
        children: [
          const Center(
            child: RxAppBarLogo(showWordmark: true, height: 40),
          ),
          const SizedBox(height: ThemeTokens.spacingLg),
          Text(
            'Privacy Policy',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ThemeTokens.spacingSm),
          Text(
            _privacyPolicy,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: ThemeTokens.spacingMd),
          Text(
            'Terms of Service',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ThemeTokens.spacingSm),
          Text(
            _termsOfService,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
