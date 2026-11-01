import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A sleek, modern, swipable and clickable status pill
/// displaying "Pending" with animated chevrons and hourglass icon,
/// or "Done" with a check icon.
///
/// Supports smooth drag gesture (swipe-to-complete) and direct tap.
class SwipableStatusPill extends StatefulWidget {
  final bool isDone;
  final VoidCallback onComplete;
  final VoidCallback? onReset;
  final bool isDark;
  final double width;
  final double height;

  const SwipableStatusPill({
    super.key,
    required this.isDone,
    required this.onComplete,
    this.onReset,
    required this.isDark,
    this.width = 150.0,
    this.height = 46.0,
  });

  @override
  State<SwipableStatusPill> createState() => _SwipableStatusPillState();
}

class _SwipableStatusPillState extends State<SwipableStatusPill>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _arrowController;
  bool _isDragging = false;

  // Thumb size & layout metrics
  double get _thumbSize => widget.height - 8.0; // 38.0
  static const double _horizontalInset = 3.5; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: widget.isDone ? 1.0 : 0.0,
    );

    // Continuous smooth looping animation for arrows moving rightwards
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (!widget.isDone) {
      _arrowController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SwipableStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone) {
      if (_arrowController.isAnimating) {
        _arrowController.stop();
      }
    } else {
      if (!_arrowController.isAnimating) {
        _arrowController.repeat();
      }
    }

    if (!_isDragging) {
      if (widget.isDone && _controller.value < 1.0) {
        _controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else if (!widget.isDone && _controller.value > 0.0) {
        _controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _isDragging = true;
    HapticFeedback.selectionClick();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    final maxTravel = widget.width - _thumbSize - (_horizontalInset * 2);
    if (maxTravel > 0) {
      final newVal = (_controller.value + delta / maxTravel).clamp(0.0, 1.0);
      _controller.value = newVal;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0.0;

    if (!widget.isDone) {
      // Swiping right from Pending to Done
      if (_controller.value >= 0.42 || velocity > 250) {
        HapticFeedback.heavyImpact();
        _controller.animateTo(1.0, curve: Curves.easeOutCubic);
        widget.onComplete();
      } else {
        _controller.animateTo(0.0, curve: Curves.easeOutCubic);
      }
    } else {
      // Swiping left from Done to Pending
      if (_controller.value <= 0.58 || velocity < -250) {
        HapticFeedback.mediumImpact();
        _controller.animateTo(0.0, curve: Curves.easeOutCubic);
        widget.onReset?.call();
      } else {
        _controller.animateTo(1.0, curve: Curves.easeOutCubic);
      }
    }
  }

  void _onTap() {
    if (!widget.isDone) {
      HapticFeedback.heavyImpact();
      _controller.animateTo(1.0, curve: Curves.easeOutCubic);
      widget.onComplete();
    } else {
      HapticFeedback.mediumImpact();
      _controller.animateTo(0.0, curve: Curves.easeOutCubic);
      widget.onReset?.call();
    }
  }

  /// Rightward moving arrows animation widget
  Widget _buildAnimatedArrows() {
    return AnimatedBuilder(
      animation: _arrowController,
      builder: (context, _) {
        final progress = _arrowController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(1, (index) {
            // Staggered wave calculation
            final delay = index * 0.28;
            final normalized = (progress - delay) % 1.0;
            // Opacity wave from 0.25 to 1.0
            final wave = math.sin(normalized * math.pi); 
            final opacity = (wave * 0.75 + 0.25).clamp(0.2, 1.0);
            // Subtle horizontal shift towards right
            final shift = normalized * 3.0;

            return Transform.translate(
              offset: Offset(shift, 0),
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Icon(
                    Icons.double_arrow_outlined,
                    size: 18,
                    color: widget.isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Color Lerp for Background
        final pendingBg1 = widget.isDark
            ? const Color(0xFF261D13)
            : const Color(0xFFFFFBEB);
        final pendingBg2 = widget.isDark
            ? const Color(0xFF1E1710)
            : const Color(0xFFFEF3C7);
        const doneBg1 = Color(0xFF166534);
        const doneBg2 = Color(0xFF14532D);

        final bg1 = Color.lerp(pendingBg1, doneBg1, t)!;
        final bg2 = Color.lerp(pendingBg2, doneBg2, t)!;

        // Color Lerp for Border
        final pendingBorder = widget.isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.45)
            : const Color(0xFFFBBF24).withValues(alpha: 0.85);
        const doneBorder = Color(0xFF22C55E);
        final borderColor = Color.lerp(pendingBorder, doneBorder, t)!;

        // Opacities for Text Crossfade
        final pendingOpacity = (1.0 - (t * 2.2)).clamp(0.0, 1.0);
        final doneOpacity = (((t - 0.45) * 2.2)).clamp(0.0, 1.0);

        // Alignment coordinate from -1.0 (far left) to 1.0 (far right)
        // Guaranteed symmetric padding on both left and right!
        final thumbAlignX = -1.0 + (t * 2.0);

        return Semantics(
          button: true,
          label: widget.isDone
              ? 'Status Done, tap or swipe left to reset'
              : 'Status Pending, swipe right or tap to complete',
          child: GestureDetector(
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onTap: _onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                gradient: LinearGradient(
                  colors: [bg1, bg2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: borderColor, width: 1.3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Pending Text Label & Animated Moving Chevrons
                  if (pendingOpacity > 0.0)
                    Positioned.fill(
                      child: Opacity(
                        opacity: pendingOpacity,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _thumbSize + _horizontalInset + 2,
                            right: 8,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isDark
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFF92400E),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  _buildAnimatedArrows(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Done Text Label & Tick (shown on left when t is high)
                  if (doneOpacity > 0.0)
                    Positioned.fill(
                      child: Opacity(
                        opacity: doneOpacity,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 10,
                            right: _thumbSize + _horizontalInset + 2,
                          ),
                          child: const Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Draggable / Animating Thumb Knob with Sharp Border and Perfect Symmetric Spacing
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _horizontalInset,
                        vertical: 4.0,
                      ),
                      child: Align(
                        alignment: Alignment(thumbAlignX, 0.0),
                        child: Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: t > 0.5
                                ? const LinearGradient(
                                    colors: [Colors.white, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFF59E0B),
                                      Color(0xFFD97706),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          ),
                          child: Center(
                            child: t > 0.5
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    size: 21,
                                    color: Color(0xFF15803D),
                                  )
                                : const Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
