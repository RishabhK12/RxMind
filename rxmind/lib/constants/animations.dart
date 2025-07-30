import 'package:flutter/material.dart';

class AnimationConstants {
  static const Duration fadeDuration = Duration(milliseconds: 600);
  static const Duration slideDuration = Duration(milliseconds: 500);
  static const Duration staggeredListDelay = Duration(milliseconds: 120);
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const double parallaxDepth1 = 0.2;
  static const double parallaxDepth2 = 0.5;
  static const double parallaxDepth3 = 0.8;
  static const double buttonPulseScale = 1.08;
  static const Duration buttonPulseDuration = Duration(milliseconds: 1200);
  static const Duration heroTransitionDuration = Duration(milliseconds: 700);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
}
