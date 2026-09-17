import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmbientWaveBackground extends StatefulWidget {
  final Widget? child;
  final Color waveColor;

  const AmbientWaveBackground({
    super.key,
    this.child,
    this.waveColor = const Color(0xFF22C55E),
  });

  @override
  State<AmbientWaveBackground> createState() => _AmbientWaveBackgroundState();
}

class _AmbientWaveBackgroundState extends State<AmbientWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            animationValue: _controller.value,
            waveColor: widget.waveColor,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;

  _WavePainter({
    required this.animationValue,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double height = size.height;

    // Draw 3 layered transparent waves across the lower and middle screen
    _drawSingleWave(
      canvas: canvas,
      size: size,
      baseHeight: height * 0.68,
      amplitude: 28,
      frequency: 1.2,
      phase: animationValue * 2 * math.pi,
      color: waveColor.withValues(alpha: 0.12),
    );

    _drawSingleWave(
      canvas: canvas,
      size: size,
      baseHeight: height * 0.76,
      amplitude: 36,
      frequency: 1.0,
      phase: (animationValue + 0.35) * 2 * math.pi,
      color: waveColor.withValues(alpha: 0.16),
    );

    _drawSingleWave(
      canvas: canvas,
      size: size,
      baseHeight: height * 0.84,
      amplitude: 24,
      frequency: 1.4,
      phase: (animationValue + 0.7) * 2 * math.pi,
      color: waveColor.withValues(alpha: 0.22),
    );
  }

  void _drawSingleWave({
    required Canvas canvas,
    required Size size,
    required double baseHeight,
    required double amplitude,
    required double frequency,
    required double phase,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: color.a * 0.4),
        ],
      ).createShader(Rect.fromLTWH(0, baseHeight - amplitude, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    for (double x = 0; x <= size.width; x += 4) {
      final double normalizedX = x / size.width;
      final double y = baseHeight +
          math.sin((normalizedX * frequency * 2 * math.pi) + phase) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveColor != waveColor;
  }
}
