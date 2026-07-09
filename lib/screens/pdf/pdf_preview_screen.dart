import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as path;
import 'package:rxmind_app/theme/brand_shadows.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';
import 'package:rxmind_app/widgets/rx_secondary_button.dart';

class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final String? exportAnnouncement;

  const PdfPreviewScreen({
    super.key,
    required this.pdfFile,
    this.exportAnnouncement,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfController _pdfController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.exportAnnouncement != null) {
      SemanticsService.announce(
        widget.exportAnnouncement!,
        TextDirection.ltr,
      );
    }
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.pdfFile.path),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _sharePdf() async {
    // Copy file path to clipboard
    try {
      await Clipboard.setData(ClipboardData(text: widget.pdfFile.path));
      if (mounted) {
        final theme = Theme.of(context);
        final ext = RxMindThemeExtension.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF file path copied to clipboard',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
            backgroundColor: ext.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error copying path: $e',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = RxMindThemeExtension.of(context);
    final fileName = path.basename(widget.pdfFile.path);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Health Report Preview',
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.primary),
            tooltip: 'Share PDF',
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: Icon(Icons.download, color: theme.colorScheme.secondary),
            tooltip: 'File saved',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'PDF saved: $fileName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                  backgroundColor: ext.success,
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: theme.colorScheme.onSecondary,
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Semantics(
        liveRegion: true,
        label: _isLoading
            ? 'Loading PDF preview'
            : _error != null
                ? 'Error loading PDF: $_error'
                : 'PDF preview ready',
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: ThemeTokens.spacingMd),
                    Text(
                      'Loading PDF...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(ThemeTokens.spacingMd),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: ThemeTokens.spacingMd),
                          Text(
                            'Error loading PDF',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: ThemeTokens.spacingSm),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ThemeTokens.spacingMd),
                        color:
                            isDark ? ThemeTokens.darkMuted : ThemeTokens.blue50,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(ThemeTokens.radiusSm),
                              ),
                              child: Icon(
                                Icons.picture_as_pdf,
                                size: 28,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Report Generated Successfully',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fileName,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PdfView(
                          controller: _pdfController,
                          scrollDirection: Axis.vertical,
                          builders: PdfViewBuilders<DefaultBuilderOptions>(
                            options: const DefaultBuilderOptions(),
                            documentLoaderBuilder: (_) => Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            pageLoaderBuilder: (_) => Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            errorBuilder: (_, error) => Center(
                              child: Text(
                                'Error: $error',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: !_isLoading && _error == null
          ? Container(
              padding: const EdgeInsets.all(ThemeTokens.spacingMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: BrandShadows.navTop(theme.brightness),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: RxSecondaryButton(
                        label: 'Close',
                        icon: Icons.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RxPrimaryButton(
                        label: 'Share',
                        icon: Icons.share,
                        onPressed: _sharePdf,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
