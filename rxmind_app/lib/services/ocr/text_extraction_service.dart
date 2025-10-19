import 'dart:io';
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
      final appDocDir = await getApplicationDocumentsDirectory();
      final tessdataDir = Directory(path.join(appDocDir.path, 'tessdata'));

      if (!await tessdataDir.exists()) {
        await tessdataDir.create(recursive: true);
      }

      _tessdataPath = tessdataDir.path;

      final engFile = File(path.join(_tessdataPath!, 'eng.traineddata'));
      if (!await engFile.exists()) {
        try {
          final data = await rootBundle.load('assets/tessdata/eng.traineddata');
          await engFile.writeAsBytes(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        } catch (e) {
          return false;
        }
      }

      _initialized = true;
      return true;
    } catch (e) {
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
      final file = File(imagePath);
      if (!file.existsSync()) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'Image file not found',
        );
      }

      final String extractedText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng',
        args: {
          "psm": "4",
          "preserve_interword_spaces": "1",
          "tessdata-dir": _tessdataPath,
        },
      );

      return ExtractionResult(
        text: extractedText,
        success: extractedText.isNotEmpty,
        errorMessage: extractedText.isEmpty ? 'No text found in image' : null,
      );
    } catch (e) {
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
      final file = File(pdfPath);
      if (!file.existsSync()) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'PDF file not found',
        );
      }

      try {
        // Open the PDF document using native_pdf_renderer
        final document = await PdfDocument.openFile(pdfPath);

        final tempDir = await getTemporaryDirectory();
        final pagesDir = Directory(path.join(tempDir.path,
            'pdf_pages_${DateTime.now().millisecondsSinceEpoch}'));
        await pagesDir.create(recursive: true);

        final int pageCount = document.pagesCount;

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
            final page = await document.getPage(i + 1);

            final pageImage = await page.render(
              width: page.width * 2,
              height: page.height * 2,
              format: PdfPageImageFormat.jpeg,
              backgroundColor: '#FFFFFF',
            );

            final imagePath = path.join(pagesDir.path, 'page_${i + 1}.jpg');
            final imageFile = File(imagePath);
            await imageFile.writeAsBytes(pageImage!.bytes);

            final pageText = await FlutterTesseractOcr.extractText(
              imagePath,
              language: 'eng',
              args: {
                "psm": "6",
                "preserve_interword_spaces": "1",
                "tessdata-dir": _tessdataPath,
              },
            );

            if (pageText.isNotEmpty) {
              fullText += '$pageText\n\n';
            }

            await page.close();
            await imageFile.delete();
          } catch (pageError) {
            // Continue with next page
          }
        }

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
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'Failed to process PDF: $pdfError',
        );
      }
    } catch (e) {
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
