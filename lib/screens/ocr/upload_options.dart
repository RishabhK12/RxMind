import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxmind_app/core/storage/local_storage.dart';
import 'package:rxmind_app/services/ocr/text_extraction_service.dart';
import 'package:rxmind_app/core/permissions/permission_disclosure_store.dart';
import 'package:rxmind_app/screens/permissions/permission_disclosure_dialog.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_card.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
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
    _checkChdConsent();
  }

  Future<void> _checkChdConsent() async {
    final hasConsent = await LocalStorage.hasChdConsent();
    if (!hasConsent && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/chdConsent');
      });
    }
  }

  Future<bool> _ensurePermissionDisclosure(PermissionType type) async {
    final key = type.name;
    if (await PermissionDisclosureStore.isAcknowledged(key)) return true;
    if (!mounted) return false;
    final disclosed = await showPermissionDisclosure(context, type);
    if (disclosed) {
      await PermissionDisclosureStore.setAcknowledged(key);
    }
    return disclosed;
  }

  Future<void> _captureFromCamera() async {
    if (!await _ensurePermissionDisclosure(PermissionType.camera)) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedFilePaths.add(photo.path);
          _hasUsedCamera = true;
        });
        await _simulateUpload();
      }
    } catch (e) {
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera not available or permission denied.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onInverseSurface,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickFromLibrary() async {
    if (!await _ensurePermissionDisclosure(PermissionType.photoLibrary)) {
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _selectedFilePaths
              .addAll(result.paths.where((p) => p != null).cast<String>());
          _hasUsedFilePicker = true;
        });
        await _simulateUpload();
      }
    } catch (e) {
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error selecting file: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
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
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
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
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Processing ${filePath.toLowerCase().endsWith('.pdf') ? 'PDF' : 'image'}: ${path.basename(filePath)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
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
        final theme = Theme.of(context);
        final ext = RxMindThemeExtension.of(context);

        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeTokens.radiusLg),
            ),
            icon: Icon(
              Icons.error_outline,
              color: ext.warning,
              size: 36,
            ),
            title: Text('Extraction Issue with ${errorFiles.length} file(s)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not extract text from: ${errorFiles.join(', ')}.\n\nError: ${errorMessage ?? 'No text was found in the document.'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: ThemeTokens.spacingMd),
                Text(
                  'Troubleshooting Tips:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: ThemeTokens.spacingSm),
                Text(
                  troubleshootingAdvice,
                  style: theme.textTheme.bodySmall,
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
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No text could be extracted from the selected files.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onInverseSurface,
              ),
            ),
            duration: const Duration(seconds: 3),
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
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error scanning document: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Widget _optionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color wellColor,
    required Color iconColor,
    required VoidCallback? onTap,
    required String semanticsLabel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: RxCard(
        onTap: onTap,
        radius: ThemeTokens.radiusLg,
        padding: const EdgeInsets.all(ThemeTokens.spacingLg),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? ThemeTokens.darkMuted : wellColor,
                borderRadius: BorderRadius.circular(ThemeTokens.radiusMd),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: ThemeTokens.spacingMd),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeTokens.spacingLg,
              vertical: ThemeTokens.spacingMd,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _optionCard(
                  context: context,
                  icon: Icons.camera_alt,
                  label: _hasUsedCamera ? 'Take Another Photo' : 'Take Photo',
                  wellColor: ThemeTokens.blue50,
                  iconColor: theme.colorScheme.primary,
                  onTap: _uploading ? null : _captureFromCamera,
                  semanticsLabel:
                      _hasUsedCamera ? 'Take Another Photo' : 'Take Photo',
                ),
                const SizedBox(height: ThemeTokens.spacingMd),
                _optionCard(
                  context: context,
                  icon: Icons.insert_drive_file,
                  label: _hasUsedFilePicker
                      ? 'Select Another PDF or Image'
                      : 'Select PDF or Image',
                  wellColor: ThemeTokens.emerald50,
                  iconColor: theme.colorScheme.secondary,
                  onTap: _uploading ? null : _pickFromLibrary,
                  semanticsLabel: _hasUsedFilePicker
                      ? 'Select Another PDF or Image'
                      : 'Select File',
                ),
                if (_selectedFilePaths.isNotEmpty) ...[
                  const SizedBox(height: ThemeTokens.spacingLg),
                  RxCard(
                    radius: ThemeTokens.radiusMd,
                    padding: const EdgeInsets.all(ThemeTokens.spacingMd),
                    child: Column(
                      children: _selectedFilePaths.map((filePath) {
                        final isPdf = filePath.toLowerCase().endsWith('.pdf');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? ThemeTokens.darkMuted
                                      : ThemeTokens.amber50,
                                  borderRadius: BorderRadius.circular(
                                      ThemeTokens.radiusSm),
                                ),
                                child: Icon(
                                  isPdf ? Icons.picture_as_pdf : Icons.image,
                                  color:
                                      RxMindThemeExtension.of(context).warning,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: ThemeTokens.spacingMd),
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
                                      isPdf ? 'PDF Document' : 'Image File',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
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
                  const SizedBox(height: ThemeTokens.spacingMd),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ThemeTokens.radiusPill),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 8,
                      backgroundColor: ThemeTokens.brandMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  ),
                ],
                if (_selectedFilePaths.isNotEmpty && !_uploading) ...[
                  const SizedBox(height: ThemeTokens.spacingXl),
                  Semantics(
                    label: 'Scan Document',
                    button: true,
                    child: RxPrimaryButton(
                      label: 'Scan Document',
                      icon: Icons.document_scanner_outlined,
                      onPressed: _scanDocument,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
