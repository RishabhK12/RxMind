import 'package:flutter/material.dart';

/// Soft card elevation recipe — keep shadow literals here, not in screens.
class BrandShadows {
  BrandShadows._();

  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> softCardFor(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ];
    }
    return softCard;
  }

  static List<BoxShadow> navTop(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.35 : 0.08;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ];
  }
}
