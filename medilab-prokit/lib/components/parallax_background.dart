import 'dart:math';
import 'package:flutter/material.dart';

class ParallaxBackground extends StatefulWidget {
  final Widget child;
  const ParallaxBackground({required this.child, Key? key}) : super(key: key);

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _particles = List.generate(18, (i) => _Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layered gradients
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFe0eafc),
                  Color(0xFFcfdef3),
                  Color(0xFFb6e0fe)
                ],
              ),
            ),
          ),
        ),
        // Parallax particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(_particles, _controller.value),
              );
            },
          ),
        ),
        // Foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _Particle {
  final double radius = 12 + Random().nextDouble() * 16;
  final double speed = 0.2 + Random().nextDouble() * 0.5;
  final double dx = Random().nextDouble();
  final double dy = Random().nextDouble();
  final Color color = Colors.white
      .withAlpha(((0.12 + Random().nextDouble() * 0.18) * 255).toInt());
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.dx * size.width + sin(progress * 2 * pi * p.speed) * 40) %
          size.width;
      final y = (p.dy * size.height + cos(progress * 2 * pi * p.speed) * 40) %
          size.height;
      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
