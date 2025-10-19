import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxmind_app/services/ocr/text_extraction_service.dart';
import 'package:path/path.dart' as path;

class UploadOptionsScreen extends StatefulWidget {
  const UploadOptionsScreen({super.key});

  @override
  State<UploadOptionsScreen> createState() => _UploadOptionsScreenState();
}

class _UploadOptionsScreenState extends State<UploadOptionsScreen> {
  final List<String> _selectedFilePaths = [];
  bool _uploading = false;
  double _uploadProgress = 0.0;
  bool _hasUsedCamera = false;
  bool _hasUsedFilePicker = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _simulateUpload() async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 100;
        });
      }
    }

    setState(() {
      _uploading = false;
    });
  }

  Future<void> _scanDocument() async {
    if (_selectedFilePaths.isEmpty) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Extract text from all selected files
      String ocrText = '';
      String? errorMessage;
      List<String> errorFiles = [];

      for (final filePath in _selectedFilePaths) {
        try {
          // Show additional extraction status
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Processing ${filePath.toLowerCase().endsWith('.pdf') ? 'PDF' : 'image'}: ${path.basename(filePath)}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          final result =
              await TextExtractionService.extractTextFromFile(filePath);

          if (result.success) {
            ocrText += '${result.text}\n\n';
          } else {
            errorFiles.add(path.basename(filePath));
            errorMessage = result.errorMessage;
          }
        } catch (extractionError) {
          errorFiles.add(path.basename(filePath));
          errorMessage = 'Unexpected error: $extractionError';
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      // If extraction failed for any file, show a message but allow continuation
      if (errorFiles.isNotEmpty) {
        final String troubleshootingAdvice =
            TextExtractionService.getTroubleshootingAdvice(
                errorFiles.first, errorMessage);

        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 36,
            ),
            title: Text('Extraction Issue with ${errorFiles.length} file(s)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not extract text from: ${errorFiles.join(', ')}.\n\nError: ${errorMessage ?? 'No text was found in the document.'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Troubleshooting Tips:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  troubleshootingAdvice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Try Again'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue with extracted text'),
              ),
            ],
          ),
        );

        if (shouldContinue == true) {
          if (!mounted) return;
          Navigator.pushNamed(context, '/reviewText', arguments: ocrText);
        }
      } else if (ocrText.isEmpty) {
        // All files processed, but no text found
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No text could be extracted from the selected files.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Text extraction successful, proceed normally
        if (!mounted) return;
        Navigator.pushNamed(context, '/reviewText', arguments: ocrText);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                label: _hasUsedCamera ? 'Take Another Photo' : 'Take Photo',
                button: true,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.camera_alt,
                      size: 24, color: theme.colorScheme.onPrimary),
                  label: Text(
                    _hasUsedCamera ? 'Take Another Photo' : 'Take Photo',
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
                  onPressed: _uploading
                      ? null
                      : () async {
                          // Use image_picker to capture photo from camera
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera);
                            if (photo != null) {
                              setState(() {
                                _selectedFilePaths.add(photo.path);
                                _hasUsedCamera = true;
                              });
                              await _simulateUpload();
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Camera not available or permission denied.')),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                label: _hasUsedFilePicker
                    ? 'Select Another PDF or Image'
                    : 'Select File',
                button: true,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.insert_drive_file,
                      size: 24, color: theme.colorScheme.onPrimary),
                  label: Text(
                    _hasUsedFilePicker
                        ? 'Select Another PDF or Image'
                        : 'Select PDF or Image',
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
                  onPressed: _uploading
                      ? null
                      : () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                              allowMultiple: true,
                            );
                            if (result != null && result.paths.isNotEmpty) {
                              setState(() {
                                _selectedFilePaths.addAll(result.paths
                                    .where((p) => p != null)
                                    .cast<String>());
                                _hasUsedFilePicker = true;
                              });
                              await _simulateUpload();
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error selecting file: $e')),
                            );
                          }
                        },
                ),
              ),
              if (_selectedFilePaths.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(77),
                    ),
                  ),
                  child: Column(
                    children: _selectedFilePaths.map((filePath) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              filePath.toLowerCase().endsWith('.pdf')
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    path.basename(filePath),
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    filePath.toLowerCase().endsWith('.pdf')
                                        ? 'PDF Document'
                                        : 'Image File',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withAlpha(153)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedFilePaths.remove(filePath);
                                  if (_selectedFilePaths.isEmpty) {
                                    _uploadProgress = 0.0;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (_uploading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ],
              const SizedBox(height: 32),
              if (_selectedFilePaths.isNotEmpty && !_uploading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan Document'),
                    onPressed: _scanDocument,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
