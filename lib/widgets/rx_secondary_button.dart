import 'package:flutter/material.dart';

/// Pill-shaped outlined secondary CTA.
class RxSecondaryButton extends StatelessWidget {
  const RxSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final button = OutlinedButton(
      onPressed: onPressed,
      child: child,
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
