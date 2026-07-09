import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme_tokens.dart';

/// Blue speech-bubble mark + optional lowercase wordmark for AppBars / splash.
class RxAppBarLogo extends StatelessWidget {
  const RxAppBarLogo({
    super.key,
    this.showWordmark = true,
    this.height = 28,
  });

  final bool showWordmark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/illus/logo.svg',
          height: height,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.primary,
            BlendMode.srcIn,
          ),
          semanticsLabel: 'RxMind logo',
        ),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          Text(
            'rxmind',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: ThemeTokens.fontFamily,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}
