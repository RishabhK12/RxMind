# OCR Functionality in RxMind App

This directory contains the text extraction services for the RxMind app, which support extracting text from both images and PDF documents.

## Components

- **TextExtractionService**: The main service that handles text extraction from various document formats.
- **PdfExtractionTest**: A utility class for testing PDF extraction independently.

## PDF Extraction Process

The PDF extraction process follows these steps:

1. **PDF Loading**: We use the `native_pdf_renderer` and `pdfx` packages to load and render PDF documents.
2. **Page Rendering**: Each page of the PDF is rendered as a high-resolution JPEG image.
3. **OCR Processing**: Tesseract OCR is used to extract text from each page image.
4. **Cleanup**: Temporary files are deleted after processing.

## Image Extraction Process

The image extraction process is simpler:

1. **Direct OCR**: We pass the image file directly to Tesseract OCR for text extraction.

## Dependencies

- **flutter_tesseract_ocr**: For OCR processing of images and rendered PDF pages.
- **native_pdf_renderer** and **pdfx**: For rendering PDF pages as images.
- **path_provider**: For managing temporary files and directories.

## Required Assets

For OCR to work properly, the following assets are required:

- `assets/tessdata/eng.traineddata`: English language data for Tesseract OCR.

## Usage

To extract text from a document:

```dart
// Initialize Tesseract first (do this once at app startup)
final initialized = await TextExtractionService.initializeTesseract();

// Extract text from an image
final imageResult = await TextExtractionService.extractTextFromImage(imagePath);

// Extract text from a PDF
final pdfResult = await TextExtractionService.extractTextFromPdf(pdfPath);

// Check the result
if (result.success) {
  // Use result.text
} else {
  // Handle error using result.errorMessage
}
```

## Testing

You can use the `PdfExtractionTest` utility class to test PDF extraction:

```dart
PdfExtractionTest.testPdfExtraction(context);
```

This opens a file picker for selecting a PDF file and then attempts to extract text from it, displaying the results in a dialog.

## Troubleshooting

If OCR is not working correctly, check the following:

1. Make sure the Tesseract language files are correctly included in the app bundle.
2. For PDF files, ensure the PDF is not encrypted or protected.
3. For image files, ensure they are of good quality and the text is clearly visible.
4. Check the console logs for detailed error messages.

## Limitations

- The OCR process may be slow for large documents.
- The quality of extracted text depends on the document quality.
- Some formatting may be lost during the OCR process.
