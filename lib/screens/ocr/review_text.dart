import 'package:flutter/material.dart';

class ReviewTextScreen extends StatefulWidget {
  const ReviewTextScreen({super.key});

  @override
  State<ReviewTextScreen> createState() => _ReviewTextScreenState();
}

class _ReviewTextScreenState extends State<ReviewTextScreen> {
  bool _editMode = false;
  late TextEditingController _controller;

  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ocrText = ModalRoute.of(context)?.settings.arguments as String?;
    _controller = TextEditingController(text: ocrText ?? '');

    // For large documents, there might be a delay in loading the text
    // into the controller, so we show a loading indicator briefly
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _editMode = !_editMode);
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, '/parsingProgress',
        arguments: _controller.text);
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
          label: 'Review Your Text',
          child: Text(
            'Review Your Text',
            style: theme.textTheme.titleLarge,
          ),
        ),
        actions: [
          Semantics(
            label: _editMode ? 'Save' : 'Edit',
            button: true,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(_editMode ? Icons.check : Icons.edit,
                    key: ValueKey(_editMode)),
              ),
              onPressed: _toggleEdit,
              tooltip: _editMode ? 'Save' : 'Edit',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing document text...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _editMode
                      ? Semantics(
                          label: 'Edit text field',
                          textField: true,
                          child: TextField(
                            key: const ValueKey('edit'),
                            controller: _controller,
                            maxLines: null,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.onSurface),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            autofocus: true,
                          ),
                        )
                      : Semantics(
                          label: 'OCR result text',
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(
                              _controller.text.isEmpty
                                  ? 'No text was found or extracted from your document. You can enter text manually by tapping the edit button above.'
                                  : _controller.text,
                              key: const ValueKey('readonly'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Semantics(
              label: 'Retake',
              button: true,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context, '/uploadOptions'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  disabledForegroundColor:
                      theme.colorScheme.primary.withOpacity(0.4),
                ),
                child: const Text('Retake'),
              ),
            ),
            const Spacer(),
            Semantics(
              label: 'Continue',
              button: true,
              child: ElevatedButton(
                onPressed: _loading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  disabledBackgroundColor:
                      theme.colorScheme.secondary.withOpacity(0.4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: _loading ? 1 : 4,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
