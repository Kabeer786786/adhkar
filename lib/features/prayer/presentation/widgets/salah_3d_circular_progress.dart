import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';

class Salah3DCircularProgress extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const Salah3DCircularProgress({
    super.key,
    required this.label,
    required this.completed,
    required this.total,
    required this.primaryColor,
    required this.secondaryColor,
    this.size = 64.0,
  });

  double get ratio => total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _Circular3DPainter(
                  progress: ratio,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  trackColor: const Color(0xFFE7E7E7),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$completed/$total',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Circular3DPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color trackColor;

  _Circular3DPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 7.0;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress <= 0) return;

    // Progress Paint
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * clampedProgress;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (primaryColor == secondaryColor) {
      progressPaint.color = primaryColor;
    } else {
      final gradient = SweepGradient(
        colors: [primaryColor, secondaryColor],
        transform: const GradientRotation(-math.pi / 2),
      );
      progressPaint.shader = gradient.createShader(rect);
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
 
    // Smooth glossy highlight tip
    if (clampedProgress > 0.05) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipCenter = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tipCenter, strokeWidth / 4.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Circular3DPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
