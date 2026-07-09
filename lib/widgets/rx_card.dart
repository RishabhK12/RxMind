import 'package:flutter/material.dart';

import '../theme/theme_tokens.dart';

/// Soft surface card with brand radius, border, and optional soft shadow.
class RxCard extends StatelessWidget {
  const RxCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.useShadow = true,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool useShadow;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = RxMindThemeExtension.of(context);
    final r = radius ?? ThemeTokens.radiusLg;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(ThemeTokens.spacingMd),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: borderColor ?? ext.border),
        boxShadow: useShadow ? ext.softShadow : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: content,
      ),
    );
  }
}
