import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ProcessingPlanScreen extends StatelessWidget {
  final String message;
  const ProcessingPlanScreen({
    this.message = 'Processing your plan... Please wait.',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white.withAlpha((0.95 * 255).toInt()),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated clipboard illustration
            SizedBox(
              height: 180,
              child: Lottie.asset(
                'assets/lottie/clipboard.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
