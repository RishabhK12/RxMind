import 'package:flutter/material.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({Key? key}) : super(key: key);

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
            'Last Updated: 11/18/2025\n\nRxMind (“we,” “us,” “our,” or “the App”) is committed to protecting your privacy and giving you control over your health information. This Privacy Policy explains how we handle your data when you use our mobile application. By using RxMind, you agree to the practices described in this Policy.\n\nWhat Information We Collect\n\nA. Information You Provide\nYou may provide photos or PDFs of discharge papers, manually entered medications, schedules, tasks, follow-up appointments, notes, reminders, and questions asked to the AI chat. This may include health information.\nB. Automatically Collected Data\nWe automatically collect device model, OS version, app performance data (such as crashes), and non-medical usage analytics. We do not automatically collect or upload any health-related information.\nC. No Account Required\nYou may use RxMind without creating an account. We do not require your name, email, phone number, or any identifying information.\n\nHow Your Data Is Stored\n\nLocal-Only Storage\nAll sensitive data, including medications, tasks, appointments, reminders, and extracted text, is stored locally on your device using Flutter Secure Storage and SharedPreferences for non-sensitive app settings. No protected health information is stored on external servers.\nData Leaves the Device Only When You Choose\nThe only time data is transmitted to external services is when you choose to use the Gemini API for document parsing or AI clarification.\n\nHow Your Data Is Used\n\nWe use your information to extract text from discharge papers using OCR, organize tasks and medications, create reminders, generate summaries or reports, provide AI-powered clarification, and improve app performance.\nWe do not sell your data, share your health information with advertisers, store raw health data on external servers, or use your data for marketing purposes.\n\nGemini and AI Processing\n\nIf you enable AI features, images or text you send to Gemini are transmitted only for processing. Raw data is not stored on Google’s servers. Data is encrypted during transmission. AI features do not provide medical advice, diagnose conditions, or recommend treatments. You may disable AI features at any time.\n\nHIPAA Considerations\n\nRxMind follows HIPAA-aligned principles such as local storage, data minimization, and encryption during transmission. However, RxMind is a prototype, is not a HIPAA-certified platform, and is not a covered entity or a medical provider.\n\nUser Controls\n\nYou may delete all app data, remove individual documents or medications, disable AI processing, export your data, or uninstall the app to remove all local data. We do not retain copies of your health data.\n\nChildren’s Privacy\n\nRxMind is not intended for children under 13, and we do not knowingly collect information from minors.\n\nSecurity Measures\n\nWe use secure local storage technologies, encrypted communication, and device-level protections. While no system is entirely secure, we take reasonable steps to safeguard your information.\n\nChanges to This Policy\n\nWe may update this Privacy Policy as needed. Continued use of the app means you accept the updated policy.\n\nContact Us\n',
          ),
          const SizedBox(height: 16),
          const Text(
            'Terms of Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Last Updated: 11/19/2025\n\nThese Terms of Service govern your use of the RxMind application. By using the app, you agree to these Terms.\n\nPurpose of the App\n\nRxMind helps users manage post-discharge recovery by scanning medical documents, extracting information, organizing tasks and medications, providing reminders, and offering AI-powered clarification.\nRxMind does not provide medical advice, diagnose conditions, replace professional healthcare, suggest medication changes, make treatment decisions, or handle emergencies.\nYou must consult your healthcare provider for medical needs.\n\nLicense to Use the App\n\nWe grant you a personal, non-transferable, revocable license to use the app. You may not reverse engineer the app, interfere with its operation, misuse AI features, upload protected health information of others without permission, or bypass safety features.\n\nAI Clarification Disclaimer\n\nThe AI clarifies information you provide. It does not provide clinical guidance, diagnose, evaluate prescriptions, or ensure accuracy. You must verify all health information with a medical professional.\n\nOCR and Extraction Limitations\n\nOCR accuracy depends on image quality and clarity. Some abbreviations may not be recognized, and complex care plans may require manual review. Extracted data is not guaranteed to be accurate, and you must confirm all information manually.\n\nConsent for AI Data Processing\n\nIf you enable Gemini features, you consent to sending selected text or images for clarification and acknowledge that the data is processed temporarily. You may disable AI features.\n\nLimitations of Liability\n\nRxMind is provided “as is.” We are not liable for medical decisions you make, incorrect or incomplete OCR results, missed reminders, data loss on your device, or errors from third-party AI systems. You accept full responsibility for how you use the app.\n\nPrivacy Policy\n\nYour use of the app is governed by the Privacy Policy.\n\nApp Updates\n\nWe may update the app at any time. Continued use after updates constitutes acceptance.\n\nTermination\n\nWe may suspend or terminate access if you violate the Terms, misuse AI features, or engage in harmful or illegal activity.\n\nGoverning Law\n\nThese Terms follow the laws of your state or country unless otherwise required.\n',
          ),
        ],
      ),
    );
  }
}