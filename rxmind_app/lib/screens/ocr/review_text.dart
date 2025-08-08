import 'package:flutter/material.dart';

class ReviewTextScreen extends StatefulWidget {
  const ReviewTextScreen({Key? key}) : super(key: key);

  @override
  State<ReviewTextScreen> createState() => _ReviewTextScreenState();
}

class _ReviewTextScreenState extends State<ReviewTextScreen> {
  bool _editMode = false;
  late TextEditingController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ocrText = ModalRoute.of(context)?.settings.arguments as String?;
    _controller = TextEditingController(text: ocrText ?? '');
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
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    child: SelectableText(
                      _controller.text,
                      key: const ValueKey('readonly'),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurface),
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
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/uploadOptions'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Retake'),
              ),
            ),
            const Spacer(),
            Semantics(
              label: 'Continue',
              button: true,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
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
