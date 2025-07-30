import 'package:flutter/material.dart';

class AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Duration duration;
  final Color activeColor;
  final Color inactiveColor;
  const AnimatedNavIcon({
    required this.icon,
    required this.active,
    this.duration = const Duration(milliseconds: 400),
    this.activeColor = const Color(0xFF3A86FF),
    this.inactiveColor = Colors.grey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeInOut,
      width: active ? 48 : 40,
      height: active ? 48 : 40,
      decoration: BoxDecoration(
        color: active
            ? activeColor.withAlpha((0.12 * 255).toInt())
            : Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: activeColor.withAlpha((0.25 * 255).toInt()),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Icon(
        icon,
        color: active ? activeColor : inactiveColor,
        size: active ? 28 : 24,
      ),
    );
  }
}
