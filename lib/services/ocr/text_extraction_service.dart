import 'dart:io';
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

import '../../core/ocr/ephemeral_buffer.dart';
import '../../core/ocr/ocr_service.dart';

/// RAM-only text extraction — no flash writes for OCR intermediates.
class TextExtractionService {
  /// Extract text from in-memory bytes (image or PDF).
  static Future<ExtractionResult> extractTextFromBytes(
    Uint8List bytes, {
    required String fileName,
  }) async {
    try {
      if (fileName.toLowerCase().endsWith('.pdf')) {
        return await _extractFromPdfBytes(bytes);
      }
      return await _extractFromImageBytes(bytes);
    } catch (e) {
      return ExtractionResult(
        text: '',
        success: false,
        errorMessage: 'Failed to extract text: $e',
      );
    }
  }

  /// Legacy path: reads file into RAM then processes ephemerally.
  static Future<ExtractionResult> extractTextFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'File not found',
        );
      }
      final bytes = await file.readAsBytes();
      final buffer = SecureBytes(bytes);
      try {
        return await extractTextFromBytes(
          buffer.data,
          fileName: filePath,
        );
      } finally {
        buffer.dispose();
      }
    } catch (e) {
      return ExtractionResult(
        text: '',
        success: false,
        errorMessage: 'Failed to read file: $e',
      );
    }
  }

  static Future<ExtractionResult> _extractFromImageBytes(
      Uint8List bytes) async {
    final buffer = SecureBytes(Uint8List.fromList(bytes));
    try {
      final text = await OcrService.extractTextFromJpegBytes(buffer.data);
      return ExtractionResult(
        text: text,
        success: text.isNotEmpty,
        errorMessage: text.isEmpty ? 'No text found in image' : null,
      );
    } finally {
      buffer.dispose();
    }
  }

  static Future<ExtractionResult> _extractFromPdfBytes(
      Uint8List pdfBytes) async {
    final docBuffer = SecureBytes(Uint8List.fromList(pdfBytes));
    try {
      final document = await PdfDocument.openData(docBuffer.data);
      final pageCount = document.pagesCount;

      if (pageCount == 0) {
        return ExtractionResult(
          text: '',
          success: false,
          errorMessage: 'PDF appears to be empty or corrupted',
        );
      }

      final pagesToProcess = pageCount > 10 ? 10 : pageCount;
      final textBuffer = StringBuffer();

      for (var i = 0; i < pagesToProcess; i++) {
        final page = await document.getPage(i + 1);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (pageImage == null) continue;

        final imageBuffer = SecureBytes(pageImage.bytes);
        try {
          final pageText =
              await OcrService.extractTextFromJpegBytes(imageBuffer.data);
          if (pageText.isNotEmpty) {
            textBuffer.writeln(pageText);
          }
        } finally {
          imageBuffer.dispose();
        }
      }

      await document.close();
      final fullText = textBuffer.toString().trim();

      return ExtractionResult(
        text: fullText,
        success: fullText.isNotEmpty,
        errorMessage:
            fullText.isEmpty ? 'Could not extract any text from the PDF' : null,
      );
    } finally {
      docBuffer.dispose();
    }
  }

  static String getTroubleshootingAdvice(
      String filePath, String? errorMessage) {
    final bool isPdf = filePath.toLowerCase().endsWith('.pdf');

    if (errorMessage != null && errorMessage.contains('tessdata')) {
      return 'OCR engine language data issue:\n'
          '• Try reinstalling the app';
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
          '• Dark text on light background';
    }
  }
}

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
