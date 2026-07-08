import 'dart:typed_data';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';

import 'ephemeral_buffer.dart';

class OcrService {
  /// Extract text from in-memory image bytes (no disk I/O).
  static Future<String> extractTextFromBytes(
    Uint8List bytes, {
    required int width,
    required int height,
  }) async {
    final buffer = SecureBytes(Uint8List.fromList(bytes));
    try {
      final inputImage = InputImage.fromBytes(
        bytes: buffer.data,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return recognizedText.text;
    } finally {
      buffer.dispose();
    }
  }

  /// Extract text from JPEG/PNG bytes using NV21-compatible metadata.
  static Future<String> extractTextFromJpegBytes(Uint8List bytes) async {
    final buffer = SecureBytes(Uint8List.fromList(bytes));
    try {
      final inputImage = InputImage.fromBytes(
        bytes: buffer.data,
        metadata: InputImageMetadata(
          size: const Size(1000, 1000),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: buffer.data.length,
        ),
      );
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      return recognizedText.text;
    } finally {
      buffer.dispose();
    }
  }
}
