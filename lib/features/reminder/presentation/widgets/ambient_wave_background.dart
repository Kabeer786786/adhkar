import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ambient continuous radial wave background.
/// Emanates beautiful concentric ripples in transparent white from the screen center
/// outwards towards the edges in an endless, rhythmic pulse.
class AmbientWaveBackground extends StatefulWidget {
  final Widget? child;
  final Color waveColor;

  const AmbientWaveBackground({
    super.key,
    this.child,
    this.waveColor = Colors.white,
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
      duration: const Duration(milliseconds: 4800),
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
          painter: _CenterRadialWavePainter(
            animationValue: _controller.value,
            waveColor: widget.waveColor,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _CenterRadialWavePainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;

  _CenterRadialWavePainter({
    required this.animationValue,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Maximum distance from center to corners to ensure waves reach the farthest edges
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2 * 1.05;

    // 1. Soft pulsing center aura
    final centerPulse = 0.5 + 0.5 * math.sin(animationValue * 2 * math.pi);
    final centerAuraRadius = 70.0 + (centerPulse * 30.0);
    final centerAuraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          waveColor.withValues(alpha: 0.12 + (centerPulse * 0.06)),
          waveColor.withValues(alpha: 0.04),
          waveColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: centerAuraRadius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, centerAuraRadius, centerAuraPaint);

    // 2. Continuous concentric waves expanding outward from center
    const int waveCount = 5;

    for (int i = 0; i < waveCount; i++) {
      final double progress = (animationValue + (i / waveCount)) % 1.0;

      // Use gentle ease-out curve for smooth fluid expansion
      final double currentRadius =
          Curves.easeOutQuad.transform(progress) * maxRadius;

      // Opacity rises as wave emerges from center, peaks midway, and softly fades at edges
      final double opacity =
          (math.sin(progress * math.pi) * 0.22).clamp(0.0, 1.0);

      if (opacity <= 0.005 || currentRadius <= 2.0) continue;

      // A. Soft glowing wavefront halo
      final haloPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0 + (progress * 26.0)
        ..isAntiAlias = true
        ..color = waveColor.withValues(alpha: opacity * 0.35);

      canvas.drawCircle(center, currentRadius, haloPaint);

      // B. Crisp primary wave contour ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 + ((1.0 - progress) * 1.6)
        ..isAntiAlias = true
        ..color = waveColor.withValues(alpha: opacity * 0.85);

      canvas.drawCircle(center, currentRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CenterRadialWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveColor != waveColor;
  }
}
