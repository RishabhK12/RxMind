import 'package:flutter/material.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Last Updated: 12/24/2025\n\nRxMind ("we," "us," "our," or "the App") is committed to protecting your privacy and giving you control over your information. This Privacy Policy explains how we handle your data when you use our mobile application. By using RxMind, you agree to the practices described in this Policy.\n\nWhat Information We Collect\n\nA. Information You Provide\nYou may provide photos or PDFs of documents you choose to upload, manually entered medications, schedules, tasks, follow-up appointments, notes, reminders, and questions typed into the app.\n\nB. No Account Required\nYou may use RxMind without creating an account. We do not require your name, email, phone number, or any identifying information.\n\nHow Your Data Is Stored\n\nLocal-Only Storage\nAll data, including medications, tasks, appointments, reminders, notes, and extracted text, is stored locally on your device using secure local storage (such as Flutter Secure Storage for sensitive data and SharedPreferences for non-sensitive app settings). RxMind does not store any user data on external servers.\n\nData Never Leaves the Device\nRxMind does not transmit your data to third-party services, cloud servers, or external APIs. All processing, organization, and functionality occur entirely on your device.\n\nHow Your Data Is Used\n\nWe use your information solely to:\n- Extract and organize information from documents\n- Create and manage tasks, medications, and reminders\n- Display summaries, checklists, and recovery progress\n- Support core app functionality and performance\n\nWe do not sell your data, share your information with advertisers, store your data externally, or use your data for marketing or analytics purposes.\n\nAI and Automated Processing\n\nRxMind may use on-device logic or automated processing to organize and display your information. All processing occurs locally on your device.\n\nRxMind does not provide medical advice, diagnose conditions, or recommend treatments. The app is intended for organizational and informational purposes only.\n\nRxMind is intended as a personal organization and reminder tool and should not be used as a substitute for professional medical care.\n\nUser Controls\n\nYou may delete all app data, remove individual documents or medications, export your data (if enabled), or uninstall the app to remove all local data. RxMind does not retain copies of your health data.\n\nChildren’s Privacy\n\nRxMind is not intended for children under 13, and we do not knowingly collect personal information from minors.\n\nSecurity Measures\n\nWe use secure local storage technologies and device-level protections to safeguard your data. While no system is entirely secure, we take reasonable steps to protect your information.\n\nChanges to This Policy\n\nWe may update this Privacy Policy as needed. Continued use of the app after changes are made constitutes acceptance of the updated policy.\n\nContact Us\n\nFor privacy questions:\n\nEmail: rxmind.app@gmail.com',
          ),
          const SizedBox(height: 16),
          const Text(
            'Terms of Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Last Updated: 12/24/2025\n\nThese Terms of Service govern your use of the RxMind application. By using the app, you agree to these Terms.\n\nPurpose of the App\n\nRxMind is a lifestyle and productivity app designed to help you organize information, create tasks and reminders, and generate summaries from content you choose to add (including optional document scans).\n\nRxMind is not a medical device and is not intended to provide medical advice, diagnosis, treatment, or emergency services. Always seek professional guidance for medical concerns and emergencies.\n\nLicense to Use the App\n\nWe grant you a personal, non-transferable, revocable license to use the app. You may not reverse engineer the app, interfere with its operation, misuse features (including AI features), upload information you do not have the right to share, or bypass safety features.\n\nOn-Device AI Assistance\n\nRxMind may include optional on-device AI features (a local LLM) to help summarize or clarify text you provide. AI output may be inaccurate or incomplete and is provided for informational and organizational purposes only. You are responsible for reviewing and verifying any content before relying on it.\n\nOCR and Extraction Limitations\n\nOCR accuracy depends on image quality and clarity. Some terms or abbreviations may not be recognized. Extracted data is not guaranteed to be accurate, and you must confirm all information manually.\n\nData Processing and Connectivity\n\nAI processing and OCR are performed locally on your device. RxMind does not require an account and does not transmit your content to external AI services for processing.\n\nLimitations of Liability\n\nRxMind is provided “as is.” We are not liable for decisions you make based on app content, incorrect or incomplete OCR/AI results, missed reminders, data loss on your device, or indirect or consequential damages. You accept full responsibility for how you use the app.\n\nPrivacy Policy\n\nYour use of the app is governed by the Privacy Policy.\n\nApp Updates\n\nWe may update the app at any time. Continued use after updates constitutes acceptance.\n\nTermination\n\nWe may suspend or terminate access if you violate the Terms, misuse features, or engage in harmful or illegal activity.\n\nGoverning Law\n\nThese Terms follow the laws of your state or country unless otherwise required.\n\nContact Us\n\nFor questions:\nEmail: rxmind.app@gmail.com',
          ),
        ],
      ),
    );
  }
}