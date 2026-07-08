import 'package:flutter/material.dart';
import 'package:rxmind_app/core/ai/report_reason.dart';

class ReportOutputSheet extends StatefulWidget {
  const ReportOutputSheet({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function(ReportReason reason, String? note) onSubmit;

  @override
  State<ReportOutputSheet> createState() => _ReportOutputSheetState();
}

Future<void> showReportOutputSheet({
  required BuildContext context,
  required Future<void> Function(ReportReason reason, String? note) onSubmit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ReportOutputSheet(onSubmit: onSubmit),
    ),
  );
}

class _ReportOutputSheetState extends State<ReportOutputSheet> {
  ReportReason? _selected;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final note = _noteController.text.trim();
      await widget.onSubmit(
        _selected!,
        note.isEmpty ? null : note,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Report Output', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...ReportReason.values.map((reason) {
            return RadioListTile<ReportReason>(
              title: Text(reason.label),
              value: reason,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
            );
          }),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Optional note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Submit report',
            button: true,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _selected == null || _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
