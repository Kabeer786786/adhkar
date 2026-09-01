import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookVerticalScrollbar extends StatefulWidget {
  final ScrollController scrollController;
  final bool isDark;

  const BookVerticalScrollbar({
    super.key,
    required this.scrollController,
    required this.isDark,
  });

  @override
  State<BookVerticalScrollbar> createState() => _BookVerticalScrollbarState();
}

class _BookVerticalScrollbarState extends State<BookVerticalScrollbar> {
  final ValueNotifier<bool> _isVisibleNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  bool _isDragging = false;
  int _lastHapticPercent = -1;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant BookVerticalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.scrollController.removeListener(_onScroll);
    _isVisibleNotifier.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  void _triggerVisibility() {
    if (!_isVisibleNotifier.value) {
      _isVisibleNotifier.value = true;
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        _isVisibleNotifier.value = false;
      }
    });
  }

  void _onScroll() {
    if (!mounted || _isDragging) return;
    if (widget.scrollController.hasClients) {
      final max = widget.scrollController.position.maxScrollExtent;
      final offset = widget.scrollController.offset;
      final p = max > 0 ? (offset / max).clamp(0.0, 1.0) : 0.0;

      _triggerVisibility();
      _progressNotifier.value = p;
    }
  }

  void _updateDrag(double localY, double availableHeight) {
    if (availableHeight <= 0) return;
    final clampedY = localY.clamp(0.0, availableHeight);
    final p = (clampedY / availableHeight).clamp(0.0, 1.0);
    final percent = (p * 100).round();

    if (percent ~/ 5 != _lastHapticPercent ~/ 5) {
      _lastHapticPercent = percent;
      HapticFeedback.selectionClick();
    }

    _progressNotifier.value = p;

    if (widget.scrollController.hasClients) {
      final max = widget.scrollController.position.maxScrollExtent;
      widget.scrollController.jumpTo((p * max).clamp(0.0, max));
    }
  }

  @override
  Widget build(BuildContext context) {
    const double thumbHeight = 36.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableTravel =
            (constraints.maxHeight - thumbHeight).clamp(1.0, double.infinity);

        return ValueListenableBuilder<bool>(
          valueListenable: _isVisibleNotifier,
          builder: (context, isVisible, _) {
            return RepaintBoundary(
              child: AnimatedSlide(
                offset: isVisible ? Offset.zero : const Offset(0.95, 0),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: 44,
                    height: constraints.maxHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topRight,
                      children: [
                        // Full height vertical drag gesture area
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 44,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragDown: (details) {
                              _isDragging = true;
                              _triggerVisibility();
                              _updateDrag(
                                details.localPosition.dy,
                                constraints.maxHeight,
                              );
                            },
                            onVerticalDragUpdate: (details) {
                              _triggerVisibility();
                              _updateDrag(
                                details.localPosition.dy,
                                constraints.maxHeight,
                              );
                            },
                            onVerticalDragEnd: (_) {
                              _isDragging = false;
                              _lastHapticPercent = -1;
                              _triggerVisibility();
                            },
                            onVerticalDragCancel: () {
                              _isDragging = false;
                              _lastHapticPercent = -1;
                              _triggerVisibility();
                            },
                          ),
                        ),

                        // Thumb handle positioned smoothly via ValueNotifier
                        ValueListenableBuilder<double>(
                          valueListenable: _progressNotifier,
                          builder: (context, progress, _) {
                            final double thumbTop = (progress * availableTravel)
                                .clamp(0.0, availableTravel);

                            return Positioned(
                              top: thumbTop,
                              right: 0,
                              child: IgnorePointer(
                                child: Container(
                                  height: thumbHeight,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? const Color(0xFF18181B)
                                        : Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(13),
                                      bottomLeft: Radius.circular(13),
                                      topRight: Radius.zero,
                                      bottomRight: Radius.zero,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: widget.isDark ? 0.35 : 0.12,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(-1, 1),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.unfold_more_rounded,
                                      color: widget.isDark
                                          ? const Color(0xFFA3E635)
                                          : const Color(0xFF2A531D),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
