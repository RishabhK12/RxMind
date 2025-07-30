import 'dart:ui';
import 'package:flutter/material.dart';

class BlurModal extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  const BlurModal({required this.child, this.blurSigma = 12, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              color: Colors.black.withAlpha((0.18 * 255).toInt()),
            ),
          ),
        ),
        Center(child: child),
      ],
    );
  }
}
