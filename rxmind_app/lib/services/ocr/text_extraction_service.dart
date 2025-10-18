import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';

/// A service to extract text from various document formats
class TextExtractionService {
  static bool _initialized = false;
  static String? _tessdataPath;

  /// Initialize Tesseract with the required language files
  static Future<bool> initializeTesseract() async {
    if (_initialized) return true;

    try {
      debugPrint('Initializing Tesseract OCR');

      // Get the application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final tessdataDir = Directory(path.join(appDocDir.path, 'tessdata'));

      // Create the tessdata directory if it doesn't exist
      if (!await tessdataDir.exists()) {
        await tessdataDir.create(recursive: true);
      }

      _tessdataPath = tessdataDir.path;

      // Check if the English trained data file exists
      final engFile = File(path.join(_tessdataPath!, 'eng.traineddata'));
      if (!await engFile.exists()) {
        debugPrint(
            'English language data not found, trying to copy from assets');

        try {
          // Try to load from assets
          final data = await rootBundle.load('assets/tessdata/eng.traineddata');
          await engFile.writeAsBytes(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
          debugPrint('Successfully copied eng.traineddata to: ${engFile.path}');
        } catch (e) {
          debugPrint('Failed to copy eng.traineddata from assets: $e');
          // If we can't load from assets, show more detailed error
          debugPrint(
              'Make sure to include assets/tessdata/eng.traineddata in your pubspec.yaml');
          return false;
        }
      }

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing Tesseract: $e');
      return false;
    }
  }

  /// Extract text from a file path, automatically detecting if it's a PDF or image
  static Future<ExtractionResult> extractTextFromFile(String filePath) async {
    try {
      // Initialize Tesseract before attempting OCR
      final initialized = await initializeTesseract();
      if (!initialized) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage:
              'Failed to initialize OCR. Language data may be missing.',
        );
      }

      if (filePath.toLowerCase().endsWith('.pdf')) {
        return await extractTextFromPdf(filePath);
      } else {
        return await extractTextFromImage(filePath);
      }
    } catch (e) {
      debugPrint('Error in extractTextFromFile: $e');
      return ExtractionResult(
        text: '',
        success: false,
        errorMessage: 'Failed to extract text: $e',
      );
    }
  }

  /// Extract text from an image file
  static Future<ExtractionResult> extractTextFromImage(String imagePath) async {
    try {
      // Check if file exists
      final file = File(imagePath);
      if (!file.existsSync()) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'Image file not found',
        );
      }

      // Use Tesseract OCR for image text extraction
      debugPrint('Using tessdata path: $_tessdataPath');
      final String extractedText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng',
        args: {
          "psm": "4", // Assume a single column of text
          "preserve_interword_spaces": "1",
          "tessdata-dir": _tessdataPath, // Use our initialized path
        },
      );

      return ExtractionResult(
        text: extractedText,
        success: extractedText.isNotEmpty,
        errorMessage: extractedText.isEmpty ? 'No text found in image' : null,
      );
    } catch (e) {
      debugPrint('Error in extractTextFromImage: $e');
      return ExtractionResult(
        text: '',
        success: false,
        errorMessage: 'Image OCR failed: $e',
      );
    }
  }

  /// Extract text from a PDF file
  static Future<ExtractionResult> extractTextFromPdf(String pdfPath) async {
    try {
      // Check if file exists
      final file = File(pdfPath);
      if (!file.existsSync()) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'PDF file not found',
        );
      }

      debugPrint('Converting PDF to images for OCR processing');

      try {
        // Open the PDF document using native_pdf_renderer
        final document = await PdfDocument.openFile(pdfPath);

        // Create a temp directory to store page images
        final tempDir = await getTemporaryDirectory();
        final pagesDir = Directory(path.join(tempDir.path,
            'pdf_pages_${DateTime.now().millisecondsSinceEpoch}'));
        await pagesDir.create(recursive: true);

        // We'll extract text from multiple pages and concatenate
        final int pageCount = document.pagesCount;
        debugPrint('PDF has $pageCount pages');

        if (pageCount == 0) {
          return ExtractionResult(
            text: '',
            success: false,
            errorMessage: 'PDF appears to be empty or corrupted',
          );
        }

        // Process up to 10 pages to avoid excessive memory usage
        final pagesToProcess = pageCount > 10 ? 10 : pageCount;
        String fullText = '';

        for (int i = 0; i < pagesToProcess; i++) {
          try {
            debugPrint('Processing page ${i + 1}');

            // Get the page
            final page = await document.getPage(i + 1);

            // Render the page as an image
            final pageImage = await page.render(
              width: page.width * 2, // Higher resolution for better OCR
              height: page.height * 2,
              format: PdfPageImageFormat.jpeg, // Using proper format from pdfx
              backgroundColor: '#FFFFFF',
            );

            // Save the image to a temporary file
            final imagePath = path.join(pagesDir.path, 'page_${i + 1}.jpg');
            final imageFile = File(imagePath);
            await imageFile.writeAsBytes(pageImage!.bytes);

            // Extract text from the page image
            final pageText = await FlutterTesseractOcr.extractText(
              imagePath,
              language: 'eng',
              args: {
                "psm": "6", // Assume a single uniform block of text
                "preserve_interword_spaces": "1",
                "tessdata-dir": _tessdataPath, // Use our initialized path
              },
            );

            if (pageText.isNotEmpty) {
              fullText += pageText + '\n\n';
            }

            // Close the page and delete the temporary image
            await page.close();
            await imageFile.delete();
          } catch (pageError) {
            debugPrint('Error processing page ${i + 1}: $pageError');
            // Continue with next page even if one fails
          }
        }

        // Close the document and clean up
        await document.close();
        await pagesDir.delete(recursive: true);

        if (fullText.isNotEmpty) {
          return ExtractionResult(
            text: fullText.trim(),
            success: true,
            errorMessage: null,
          );
        } else {
          return ExtractionResult(
            text: '',
            success: false,
            errorMessage: 'Could not extract any text from the PDF pages',
          );
        }
      } catch (pdfError) {
        debugPrint('PDF processing error: $pdfError');
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'Failed to process PDF: $pdfError',
        );
      }
    } catch (e) {
      debugPrint('Error in extractTextFromPdf: $e');
      return ExtractionResult(
        text: '',
        success: false,
        errorMessage: 'PDF text extraction failed: $e',
      );
    }
  }

  /// Get helpful troubleshooting advice based on the file type and error
  static String getTroubleshootingAdvice(
      String filePath, String? errorMessage) {
    final bool isPdf = filePath.toLowerCase().endsWith('.pdf');

    // Check for specific Tesseract errors
    if (errorMessage != null) {
      if (errorMessage.contains('tessdata')) {
        return 'OCR engine language data issue:\n'
            '• The OCR language files may be missing\n'
            '• Try reinstalling the app\n'
            '• If you\'re a developer, ensure tessdata is included in assets';
      }
    }

    if (isPdf) {
      return 'PDF extraction can be challenging with:\n'
          '• Scanned PDFs with no embedded text\n'
          '• Password-protected PDFs\n'
          '• Heavily formatted documents\n\n'
          'Try with a different PDF or use a clearer image of your document.';
    } else {
      return 'Image OCR works best with:\n'
          '• Clear, well-lit photos\n'
          '• Minimal glare or shadows\n'
          '• Text that is properly aligned\n'
          '• Dark text on light background\n\n'
          'Try taking another photo with better lighting or a steadier hand.';
    }
  }
}

/// Result of a text extraction operation
class ExtractionResult {
  final String text;
  final bool success;
  final String? errorMessage;

  ExtractionResult({
    required this.text,
    required this.success,
    this.errorMessage,
  });
}
