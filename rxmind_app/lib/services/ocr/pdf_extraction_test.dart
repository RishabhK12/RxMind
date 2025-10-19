import 'dart:io';
import 'package:flutter/material.dart';
import 'text_extraction_service.dart';
import 'package:file_picker/file_picker.dart';

/// A utility class to test PDF extraction functionality
class PdfExtractionTest {
  /// Test the PDF extraction functionality by picking a PDF file
  /// and extracting text from it
  static Future<void> testPdfExtraction(BuildContext context) async {
    try {
      // Initialize Tesseract first
      final initialized = await TextExtractionService.initializeTesseract();
      if (!initialized) {
        _showMessage(context, 'Failed to initialize Tesseract OCR engine');
        return;
      }

      // Pick a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        _showMessage(context, 'No PDF file selected');
        return;
      }

      final file = File(result.files.first.path!);
      if (!file.existsSync()) {
        _showMessage(context, 'Selected file does not exist');
        return;
      }

      // Show loading indicator
      _showLoadingDialog(context, 'Extracting text from PDF...');

      // Extract text from PDF
      final extractionResult =
          await TextExtractionService.extractTextFromPdf(file.path);

      // Hide loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      // Show result
      if (extractionResult.success) {
        final extractedText = extractionResult.text;
        _showResultDialog(
            context, 'PDF Text Extraction Successful', extractedText);
      } else {
        _showMessage(
          context,
          'PDF extraction failed: ${extractionResult.errorMessage ?? "Unknown error"}',
        );
      }
    } catch (e) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      _showMessage(context, 'Error testing PDF extraction: $e');
    }
  }

  /// Show a loading dialog with a message
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  /// Show a snackbar message
  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show a dialog with the extracted text result
  static void _showResultDialog(
      BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Text(content.isEmpty ? 'No text extracted' : content),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
