# RxMind

**Public site:** https://<org>.github.io/RxMind/

This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a licensed healthcare professional for medical advice.

RxMind is a mobile app designed to help patients manage their post-discharge care more effectively. We built this because navigating medical discharge papers can be overwhelming - they're full of complicated instructions, medication schedules, and follow-up appointments that are easy to miss. RxMind helps you log and organize discharge information into an easy-to-follow plan.

## What Does It Do?

- **Document Upload**: Take a photo or select a PDF of your discharge papers for on-device text extraction
- **Medication Tracking**: Never forget a dose again with reminders and a simple check-off system
- **Task Management**: All your recovery instructions in one place - wound care, physical therapy exercises, dietary restrictions, you name it
- **Follow-up Appointments**: Keep track of when and where you need to go for checkups
- **Wellness Assistant**: On-device AI chat (Phase 3) — currently shows a placeholder while local inference is integrated
- **Compliance Tracking**: See how well you're sticking to your recovery plan with visual charts
- **PDF Reports**: Generate shareable reports for your doctor or family members

## Getting Started

### Prerequisites

You'll need:

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Android Studio or VS Code

### Installation

1. Clone this repo:

```bash
git clone https://github.com/RishabhK12/RxMind.git
cd RxMind
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

That's it! The app should launch on your connected device or emulator. No backend URL, API keys, or `.env` file are required.

### AI Features (Local-Only)

RxMind does **not** use cloud AI inference. Structured document parsing and chat responses will be powered by an on-device quantized model in **Phase 3** of the engineering roadmap. Until then, AI surfaces display a local-only placeholder message.

## Privacy & Security

We take your health data seriously:

- **All data stays on your device** — medications, tasks, and personal info are stored locally
- **No account required** — you don't need to sign up or give us any personal information
- **No cloud AI transmission** — health data is never sent to remote inference endpoints
- **Local-only architecture** — see `docs/roadmap.md` for the compliance engineering plan

## How to Use

1. **First Launch**: Set up your profile (optional but helpful for personalized reminders)
2. **Upload Discharge Papers**: Tap the upload button and either take a photo or select a PDF of your discharge instructions
3. **Review Extracted Data**: Review and manually edit medications, tasks, appointments, and warnings on the summary screen
4. **Track Daily**: Check off medications and tasks as you complete them
5. **Ask Questions**: Use the chat feature when on-device AI becomes available (Phase 3)
6. **Export Report**: Generate a PDF summary to share with family or bring to follow-up appointments

## Tech Stack

Built with Flutter and Dart, using:

- Tesseract OCR for on-device document text extraction
- Local secure storage (SQLCipher planned — see roadmap)
- Syncfusion Charts for compliance visualization
- Flutter Local Notifications for medication reminders

## Known Issues

- OCR works best with clear, well-lit photos of printed text
- Automatic structured parsing is unavailable until Phase 3 on-device AI ships
- Recurring tasks currently support daily/weekly/monthly patterns only

## Contributing

Found a bug? Have an idea? We'd love to hear from you! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Built as part of the Congressional App Challenge 2025. Thanks to everyone who provided feedback during development, especially the healthcare workers who helped us understand what patients actually need.

## Contact

Have questions? Reach out to us through the GitHub issues page or contact the maintainers directly.

---

**Disclaimer**: This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a licensed healthcare professional for medical advice.
