# Tesseract OCR Language Files

This directory contains the Tesseract OCR language data files required for text extraction from images and PDFs.

## Required Files

The primary file needed is:

- **eng.traineddata** (English language data)

## Setup Instructions

### For Developers:

1. **Download the language data file:**

   - Visit: https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata
   - Save this file to both:
     - `assets/tessdata/eng.traineddata` (for Flutter assets)
     - `android/app/src/main/assets/tessdata/eng.traineddata` (for Android)
     - `ios/Runner/Assets/tessdata/eng.traineddata` (for iOS)

2. **Verify your pubspec.yaml includes:**

   ```yaml
   flutter:
     assets:
       - assets/tessdata/
       - assets/tessdata/eng.traineddata
       - assets/tessdata_config.json
   ```

3. **For iOS deployment:**
   Make sure to add the tessdata folder to your iOS project in Xcode.

### For Additional Languages:

If you want to support languages other than English:

1. Download additional language files from: https://github.com/tesseract-ocr/tessdata
2. Add them to the same locations as the English file
3. Update the language parameter in the OCR code

## Troubleshooting

If OCR is not working:

1. **Check file existence:**

   - Verify that `eng.traineddata` exists in all required locations
   - The file is quite large (~30MB) and may not be included in git repositories

2. **Common OCR issues:**

   - For images: Use clear, well-lit photos with good contrast
   - For PDFs: Native PDFs work better than scanned documents
   - Text alignment: Ensure text is properly oriented/aligned

3. **App-specific issues:**
   - Try restarting the app
   - Update to the latest version
   - Check app permissions for file access
