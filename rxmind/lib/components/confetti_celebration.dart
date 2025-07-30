import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ConfettiCelebration extends StatelessWidget {
  final VoidCallback? onEnd;
  const ConfettiCelebration({this.onEnd, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Lottie.asset(
            'assets/lottie/confetti.json',
            repeat: false,
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                if (onEnd != null) onEnd!();
              });
            },
          ),
        ),
      ],
    );
  }
}
