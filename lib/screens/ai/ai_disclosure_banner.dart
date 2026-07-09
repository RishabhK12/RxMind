import 'package:flutter/material.dart';
import 'package:rxmind_app/theme/theme_tokens.dart';
import 'package:rxmind_app/widgets/rx_primary_button.dart';

class AiDisclosureBanner extends StatelessWidget {
  const AiDisclosureBanner({super.key, required this.onAcknowledged});

  final VoidCallback onAcknowledged;

  static const disclosureText =
      'You are interacting with an automated on-device AI system, not a human clinician.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        Theme.of(context).extension<RxMindThemeExtension>()?.aiAccent ??
            ThemeTokens.brandViolet;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ThemeTokens.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 28,
                color: accent,
              ),
              const SizedBox(height: ThemeTokens.spacingLg),
              Semantics(
                header: true,
                child: Text(
                  disclosureText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: ThemeTokens.spacingXl),
              Semantics(
                label: 'I Understand',
                button: true,
                child: RxPrimaryButton(
                  label: 'I Understand',
                  onPressed: onAcknowledged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
