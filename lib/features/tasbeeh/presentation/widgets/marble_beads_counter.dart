import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarbleBeadsCounter extends StatefulWidget {
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final double height;
  final String marbleAsset;
  final bool swipeLeftToRight;

  const MarbleBeadsCounter({
    super.key,
    required this.onIncrement,
    this.onDecrement,
    this.height = 210,
    this.marbleAsset = 'assets/images/marble1.png',
    this.swipeLeftToRight = false,
  });

  @override
  State<MarbleBeadsCounter> createState() => MarbleBeadsCounterState(); 
}

class MarbleBeadsCounterState extends State<MarbleBeadsCounter> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  bool _isAnimating = false;
  double _dragProgress = 0.0; // [-1.0, 1.0] live real-time drag offset
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _animController.addListener(() {
      setState(() {
        _dragProgress = _slideAnim.value;
      });
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isForward) {
          widget.onIncrement();
        } else {
          widget.onDecrement?.call();
        }
        HapticFeedback.lightImpact();
        _animController.reset();
        setState(() {
          _isAnimating = false;
          _dragProgress = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void triggerTapIncrement() {
    if (!_isAnimating) {
      _finishStep(forward: true);
    }
  }

  void _finishStep({required bool forward}) {
    if (_isAnimating) return;
    _isForward = forward;
    _isAnimating = true;

    final target = forward ? 1.0 : -1.0;
    _slideAnim = Tween<double>(begin: _dragProgress, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  void _snapBackToZero() {
    if (_isAnimating) return;
    _isAnimating = true;
    _slideAnim = Tween<double>(begin: _dragProgress, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        _animController.reset();
        setState(() {
          _isAnimating = false;
          _dragProgress = 0.0;
        });
      }
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      final delta = widget.swipeLeftToRight ? details.delta.dx : -details.delta.dx;
      _dragProgress += delta / 220.0;
      _dragProgress = _dragProgress.clamp(-1.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final velocityX = widget.swipeLeftToRight
        ? details.velocity.pixelsPerSecond.dx
        : -details.velocity.pixelsPerSecond.dx;

    // Strict threshold: requires full traversal (>= 0.75 progress or fast fling >= 0.55)
    if (_dragProgress >= 0.5 || (_dragProgress >= 0.45 && velocityX > 350)) {
      _finishStep(forward: true);
    } else if (_dragProgress <= -0.5 || (_dragProgress <= -0.45 && velocityX < -350)) {
      _finishStep(forward: false);
    } else {
      _snapBackToZero();
    }
  }

  Offset _getPhysicalBeadPos(int beadIndex, double progress, double width, double height) {
    const beadSize = 52.0;
    const touchStep = beadSize - 1.2;
    const centerGap = 110.0; // Distinct gap between left and right groups

    final centerX = width / 2;
    final centerY = height / 2;

    // Static base resting X positions
    double staticX(int idx) {
      if (idx <= -1) {
        return centerX - (centerGap / 2) - (beadSize / 2) + ((idx + 1) * touchStep);
      } else {
        return centerX + (centerGap / 2) + (beadSize / 2) + ((idx - 1) * touchStep);
      }
    }

    double rawX = staticX(beadIndex);

    // Dynamic 2-Phase Collision Physical Motion
    if (progress > 0) {
      // FORWARD SWIPE (swiping left, p in [0, 1])
      const pTouch = 0.65; // Fraction when lead marble reaches right edge of marble -1
      final targetLeadX = staticX(-1) + touchStep; // Stops directly adjacent to marble -1

      if (beadIndex == 1) {
        // Leading right marble #1 slides left across center gap until it touches marble -1!
        if (progress <= pTouch) {
          final frac = progress / pTouch;
          rawX = staticX(1) + (targetLeadX - staticX(1)) * frac;
        } else {
          // Phase 2: Contact made! Shifts left along with the left group
          final shiftFrac = (progress - pTouch) / (1.0 - pTouch);
          rawX = targetLeadX - shiftFrac * touchStep;
        }
      } else if (beadIndex <= -1) {
        // Left group stays stationary until lead marble touches it!
        if (progress <= pTouch) {
          rawX = staticX(beadIndex);
        } else {
          final shiftFrac = (progress - pTouch) / (1.0 - pTouch);
          rawX = staticX(beadIndex) - shiftFrac * touchStep;
        }
      } else if (beadIndex >= 2) {
        // Remaining right group stays stationary until collision!
        if (progress <= pTouch) {
          rawX = staticX(beadIndex);
        } else {
          final shiftFrac = (progress - pTouch) / (1.0 - pTouch);
          rawX = staticX(beadIndex) - shiftFrac * touchStep;
        }
      }
    } else if (progress < 0) {
      // REVERSE SWIPE (swiping right, absP in [0, 1])
      final absP = -progress;
      const pTouch = 0.65;
      final targetLeadX = staticX(1) - touchStep; // Stops directly adjacent to marble 1

      if (beadIndex == -1) {
        // Rightmost left marble #-1 slides right across center gap until it touches marble 1!
        if (absP <= pTouch) {
          final frac = absP / pTouch;
          rawX = staticX(-1) + (targetLeadX - staticX(-1)) * frac;
        } else {
          // Phase 2: Contact made! Shifts right along with the right group
          final shiftFrac = (absP - pTouch) / (1.0 - pTouch);
          rawX = targetLeadX + shiftFrac * touchStep;
        }
      } else if (beadIndex >= 1) {
        // Right group stays stationary until hit!
        if (absP <= pTouch) {
          rawX = staticX(beadIndex);
        } else {
          final shiftFrac = (absP - pTouch) / (1.0 - pTouch);
          rawX = staticX(beadIndex) + shiftFrac * touchStep;
        }
      } else if (beadIndex <= -2) {
        // Remaining left group stays stationary until hit!
        if (absP <= pTouch) {
          rawX = staticX(beadIndex);
        } else {
          final shiftFrac = (absP - pTouch) / (1.0 - pTouch);
          rawX = staticX(beadIndex) + shiftFrac * touchStep;
        }
      }
    }

    // Map rawX to Tilted Inverted U Rope Y coordinate
    final u = ((rawX - centerX) / (width / 2.1)).clamp(-1.3, 1.3);
    final y = (centerY + 22.0) - 38.0 * math.cos(u * (math.pi / 2.2)) - 14.0 * u;

    return Offset(rawX, y);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: triggerTapIncrement,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // 3 marbles left (-3, -2, -1), 6 marbles right (1, 2, 3, 4, 5, 6)
            // Plus buffer indices (-4, 7) for entry/exit
            final beadIndices = [-4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7];

            final effectiveProgress = widget.swipeLeftToRight ? -_dragProgress : _dragProgress;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Tilted Inverted U Rope path painter
                CustomPaint(
                  size: Size(width, height),
                  painter: _TiltedRopePainter(
                    getPoint: (rawX) {
                      final u = ((rawX - width / 2) / (width / 2.1)).clamp(-1.3, 1.3);
                      final y = (height / 2 + 22.0) - 38.0 * math.cos(u * (math.pi / 2.2)) - 14.0 * u;
                      return Offset(rawX, y);
                    },
                  ),
                ),

                // Render 100% opaque Marble Beads with selected marbleAsset image
                ...beadIndices.map((baseIdx) {
                  final pt = _getPhysicalBeadPos(baseIdx, effectiveProgress, width, height);

                  // 100% Opacity on screen, only fade out offscreen boundaries
                  double opacity = 1.0;
                  if (pt.dx < 10) {
                    opacity = (pt.dx / 10.0).clamp(0.0, 1.0);
                  } else if (pt.dx > width - 10) {
                    opacity = ((width - pt.dx) / 10.0).clamp(0.0, 1.0);
                  }

                  const beadSize = 52.0;

                  return Positioned(
                    left: pt.dx - (beadSize / 2),
                    top: pt.dy - (beadSize / 2),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: beadSize,
                        height: beadSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(1, 2.5),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          widget.marbleAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0xFF81D4FA), Color(0xFF0284C7)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TiltedRopePainter extends CustomPainter {
  final Offset Function(double rawX) getPoint;

  _TiltedRopePainter({required this.getPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final steps = 70;
    final startX = -20.0;
    final endX = size.width + 20.0;

    for (int i = 0; i <= steps; i++) {
      final x = startX + (i / steps) * (endX - startX);
      final pt = getPoint(x);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    final shadowPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path.shift(const Offset(1, 2.5)), shadowPaint);

    final mainPaint = Paint()
      ..color = const Color(0xFFC69C6D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = const Color(0xFFF3E5AB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, mainPaint);
    canvas.drawPath(path.shift(const Offset(-0.5, -0.5)), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
