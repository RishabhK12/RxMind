import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';

class UploadOptionsScreen extends StatefulWidget {
  const UploadOptionsScreen({super.key});

  @override
  State<UploadOptionsScreen> createState() => _UploadOptionsScreenState();
}

class _UploadOptionsScreenState extends State<UploadOptionsScreen> {
  String? _selectedFilePath;
  bool _uploading = false;
  bool _uploadComplete = false;
  double _uploadProgress = 0.0;

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
      _uploadComplete = true;
    });
  }

  Future<void> _scanDocument() async {
    if (_selectedFilePath == null) return;

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

      final ocrText = await TesseractOcr.extractText(_selectedFilePath!);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      Navigator.pushNamed(context, '/reviewText', arguments: ocrText);
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
                  onPressed: _uploadComplete
                      ? null
                      : () async {
                          // Use image_picker to capture photo from camera
                          try {
                            final ImagePicker picker = ImagePicker();
                            final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera);
                            if (photo != null) {
                              setState(() {
                                _selectedFilePath = photo.path;
                              });
                              await _simulateUpload();
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Camera not available or permission denied.')),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
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
                  onPressed: _uploadComplete
                      ? null
                      : () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                _selectedFilePath = result.files.single.path;
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
              if (_selectedFilePath != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insert_drive_file,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFilePath!.split('/').last,
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_uploadComplete)
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                        ],
                      ),
                      if (_uploading) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading... ${(_uploadProgress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_uploadComplete) ...[
                const SizedBox(height: 24),
                Semantics(
                  label: 'Scan Document',
                  button: true,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.document_scanner,
                        size: 24, color: theme.colorScheme.onPrimary),
                    label: Text(
                      'Scan Document',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(200, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _scanDocument,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
