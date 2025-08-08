import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

class UploadOptionsScreen extends StatelessWidget {
  const UploadOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Semantics(
          label: 'Scan or Import',
          child: Text(
            'Scan or Import',
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
      body: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: 'Take Photo',
                  button: true,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt,
                        size: 24, color: theme.colorScheme.onPrimary),
                    label: Text(
                      'Take Photo',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      // TODO: Implement camera capture and OCR
                      // For now, pick an image from file picker as a stand-in for camera
                      final result = await FilePicker.platform
                          .pickFiles(type: FileType.image);
                      if (result != null && result.files.single.path != null) {
                        final ocrText = await TesseractOcr.extractText(
                            result.files.single.path!);
                        // Navigate to review text screen with OCR result
                        // ignore: use_build_context_synchronously
                        Navigator.pushNamed(context, '/reviewText',
                            arguments: ocrText);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  label: 'Select File',
                  button: true,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.insert_drive_file,
                        size: 24, color: theme.colorScheme.onPrimary),
                    label: Text(
                      'Select File',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform
                          .pickFiles(type: FileType.any);
                      if (result != null && result.files.single.path != null) {
                        final ocrText = await TesseractOcr.extractText(
                            result.files.single.path!);
                        // Navigate to review text screen with OCR result
                        // ignore: use_build_context_synchronously
                        Navigator.pushNamed(context, '/reviewText',
                            arguments: ocrText);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
