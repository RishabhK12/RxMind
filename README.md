# RxMind

**Your Personal Health Recovery Assistant**

RxMind is a mobile app designed to help patients manage their post-discharge care more effectively. We built this because navigating medical discharge papers can be overwhelming - they're full of complicated instructions, medication schedules, and follow-up appointments that are easy to miss. RxMind simplifies this by scanning your discharge papers and organizing everything into an easy-to-follow plan.

## What Does It Do?

- **Smart Document Scanning**: Take a photo of your discharge papers and RxMind extracts all the important information automatically
- **Medication Tracking**: Never forget a dose again with automatic reminders and a simple check-off system
- **Task Management**: All your recovery instructions in one place - wound care, physical therapy exercises, dietary restrictions, you name it
- **Follow-up Appointments**: Keep track of when and where you need to go for checkups
- **Health Assistant**: Ask questions about your medications or discharge instructions and get helpful answers
- **Compliance Tracking**: See how well you're sticking to your recovery plan with visual charts
- **PDF Reports**: Generate shareable reports for your doctor or family members

## Getting Started

### Prerequisites

You'll need:

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Android Studio or VS Code
- (Optional) Access to the RxMind Cloudflare Worker URL if you plan to use a
  custom backend environment

### Installation

1. Clone this repo:

```bash
git clone https://github.com/RishabhK12/RxMind.git
cd RxMind/rxmind_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Deploy the Cloudflare Worker (Required for AI features):

   RxMind proxies all Gemini API requests through a Cloudflare Worker to keep the API key secure.
   **The bundled worker URL will not work until you deploy it.**

   Quick setup:

   ```bash
   cd cloudflare-worker
   npm install
   npx wrangler login
   npx wrangler secret put GEMINI_API_KEY
   # Paste your Gemini API key from https://aistudio.google.com/apikey
   npx wrangler deploy
   ```

   After deploying, either:

   - Update `lib/config/backend_config.dart` line 17 with your live `*.workers.dev` URL, **OR**
   - Create `.env` (copy `.env.example`) and set `BACKEND_BASE_URL=https://your-worker.workers.dev`

   See [`BACKEND_SETUP.md`](./BACKEND_SETUP.md) for detailed instructions and troubleshooting.

4. Run the app:

```bash
flutter run
```

That's it! The app should launch on your connected device or emulator.

### Important: AI Features Require Backend Deployment

The app defaults to `https://rxmind-gemini-proxy.rishabhk12.workers.dev`, but this URL **is not deployed by default**.
You must deploy the Cloudflare Worker (step 3 above) before AI features work. See [`BACKEND_SETUP.md`](./BACKEND_SETUP.md) for help.

## Privacy & Security

We take your health data seriously:

- **All data stays on your device** - medications, tasks, and personal info are stored locally using Flutter's secure storage
- **No account required** - you don't need to sign up or give us any personal information
- **Gemini API** is only used for parsing discharge papers and answering health questions - your raw data isn't stored on Google's servers
- **HIPAA Considerations** - while we've designed the app with privacy in mind, this is a prototype and hasn't undergone formal HIPAA compliance certification

## How to Use

1. **First Launch**: Set up your profile (optional but helpful for personalized reminders)
2. **Scan Discharge Papers**: Tap the upload button and either take a photo or select a PDF of your discharge instructions
3. **Review Extracted Data**: The app will parse your document and show you medications, tasks, appointments, and warnings
4. **Track Daily**: Check off medications and tasks as you complete them
5. **Ask Questions**: Use the chat feature if you're confused about any instructions
6. **Export Report**: Generate a PDF summary to share with family or bring to follow-up appointments

## Tech Stack

Built with Flutter and Dart, using:

- Google's Gemini API for smart text extraction and health Q&A
- Tesseract OCR for document scanning
- SharedPreferences for local data storage
- Syncfusion Charts for compliance visualization
- Flutter Local Notifications for medication reminders

## Known Issues

- OCR works best with clear, well-lit photos of printed text
- Some medical abbreviations might not be recognized perfectly
- Recurring tasks currently support daily/weekly/monthly patterns only
- The app hasn't been tested with extremely complex medication regimens (10+ different medications)

## Contributing

Found a bug? Have an idea? We'd love to hear from you! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Built as part of the Congressional App Challenge 2025. Thanks to everyone who provided feedback during development, especially the healthcare workers who helped us understand what patients actually need.

## Contact

Have questions? Reach out to us through the GitHub issues page or contact the maintainers directly.

---

**Disclaimer**: RxMind is meant to help you manage your recovery, not replace professional medical advice. Always consult your healthcare provider if you have concerns about your treatment plan.
