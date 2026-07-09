import 'package:flutter/material.dart';
import 'package:rxmind_app/core/ai/report_reason.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(ThemeTokens.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: ThemeTokens.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(context)
                        .extension<RxMindThemeExtension>()
                        ?.border ??
                    ThemeTokens.brandBorder,
                borderRadius: BorderRadius.circular(ThemeTokens.radiusPill),
              ),
            ),
          ),
          Text('Report Output', style: theme.textTheme.titleLarge),
          const SizedBox(height: ThemeTokens.spacingMd),
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
            ),
          ),
          const SizedBox(height: ThemeTokens.spacingSm),
          Semantics(
            label: 'Submit report',
            button: true,
            child: _submitting
                ? const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : RxPrimaryButton(
                    label: 'Submit',
                    onPressed: _selected == null ? null : _submit,
                  ),
          ),
        ],
      ),
    );
  }
}
