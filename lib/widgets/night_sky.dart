import 'dart:math';
import 'package:flutter/material.dart';

class NightSky extends StatefulWidget {
  const NightSky({super.key});

  @override
  State<NightSky> createState() => _NightSkyState();
}

class _NightSkyState extends State<NightSky>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          painter: NightSkyPainter(_controller.value),
        );
      },
    );
  }
}

class NightSkyPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(1);

  NightSkyPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    /// ✨ STARS
    for (int i = 0; i < 40; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 1.5 + 0.5;

      canvas.drawCircle(Offset(dx, dy), radius, starPaint);
    }

    /// ☄️ METEOR
    final meteorPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final meteorX = size.width * progress;
    final meteorY = size.height * 0.2;

    canvas.drawLine(
      Offset(meteorX - 80, meteorY - 40),
      Offset(meteorX, meteorY),
      meteorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant NightSkyPainter oldDelegate) {
    return true;
  }
}