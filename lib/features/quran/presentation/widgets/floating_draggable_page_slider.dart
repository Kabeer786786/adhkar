import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class FloatingDraggablePageSlider extends StatefulWidget {
  final PageController pageController;
  final int totalPages;
  final int currentPage;
  final bool isDark;
  final ValueChanged<int>? onPageChanged;

  const FloatingDraggablePageSlider({
    super.key,
    required this.pageController,
    required this.totalPages,
    required this.currentPage,
    required this.isDark,
    this.onPageChanged,
  });

  @override
  State<FloatingDraggablePageSlider> createState() =>
      _FloatingDraggablePageSliderState();
}

class _FloatingDraggablePageSliderState
    extends State<FloatingDraggablePageSlider> {
  bool _isVisible = false;
  bool _isDragging = false;
  double _progress = 0.0; // 0.0 at right edge (Page 1), 1.0 at left edge (Last Page)
  int _lastHapticPage = -1;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _syncProgressFromCurrentPage();
    widget.pageController.addListener(_onPageScroll);
  }

  @override
  void didUpdateWidget(covariant FloatingDraggablePageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController.removeListener(_onPageScroll);
      widget.pageController.addListener(_onPageScroll);
    }
    if (oldWidget.currentPage != widget.currentPage && !_isDragging) {
      _syncProgressFromCurrentPage();
      _triggerVisibility();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.pageController.removeListener(_onPageScroll);
    super.dispose();
  }

  void _syncProgressFromCurrentPage() {
    if (widget.totalPages <= 1) {
      _progress = 0.0;
      return;
    }
    final p = (widget.currentPage / (widget.totalPages - 1)).clamp(0.0, 1.0);
    _progress = p;
  }

  void _triggerVisibility() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _onPageScroll() {
    if (!mounted || _isDragging) return;
    if (widget.pageController.hasClients &&
        widget.pageController.position.haveDimensions) {
      final page = widget.pageController.page ?? widget.currentPage.toDouble();
      if (widget.totalPages > 1) {
        final p = (page / (widget.totalPages - 1)).clamp(0.0, 1.0);
        _triggerVisibility();
        if ((p - _progress).abs() > 0.001) {
          setState(() {
            _progress = p;
          });
        }
      }
    }
  }

  void _updateDrag(double localX, double totalWidth) {
    if (totalWidth <= 0 || widget.totalPages <= 1) return;
    // Right-to-Left (RTL):
    // localX at totalWidth (right) -> progress 0.0 (Page 1)
    // localX at 0 (left) -> progress 1.0 (Last Page)
    final clampedX = localX.clamp(0.0, totalWidth);
    final p = (1.0 - (clampedX / totalWidth)).clamp(0.0, 1.0);
    final targetPage =
        ((widget.totalPages - 1) * p).round().clamp(0, widget.totalPages - 1);

    if (targetPage != _lastHapticPage) {
      _lastHapticPage = targetPage;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _progress = p;
    });

    if (widget.pageController.hasClients) {
      widget.pageController.jumpToPage(targetPage);
    }
    widget.onPageChanged?.call(targetPage);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalPages <= 1) return const SizedBox.shrink();

    final int displayPageNum =
        ((widget.totalPages - 1) * _progress).round() + 1;

    // Width 36.0, height 40.0
    const double thumbWidth = 36.0;
    const double thumbHeight = 40.0;
    const double pillWidth = 96.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableTravel =
            (constraints.maxWidth - thumbWidth).clamp(1.0, double.infinity);
        final double thumbLeft =
            ((1.0 - _progress) * availableTravel).clamp(0.0, availableTravel);

        // Position pill smoothly centered on thumb, bounded inside screen margins
        final double pillLeft = (thumbLeft + (thumbWidth / 2) - (pillWidth / 2))
            .clamp(10.0, (constraints.maxWidth - pillWidth - 10.0).clamp(10.0, double.infinity));

        return RepaintBoundary(
          child: AnimatedSlide(
            offset: _isVisible ? Offset.zero : const Offset(0, 0.95),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: SizedBox(
                width: constraints.maxWidth,
                height: 76,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    // Full width horizontal drag gesture area
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 76,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragDown: (details) {
                          setState(() => _isDragging = true);
                          _triggerVisibility();
                          _updateDrag(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                        },
                        onHorizontalDragUpdate: (details) {
                          _triggerVisibility();
                          _updateDrag(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                        },
                        onHorizontalDragEnd: (_) {
                          setState(() {
                            _isDragging = false;
                            _lastHapticPage = -1;
                          });
                          _triggerVisibility();
                        },
                        onHorizontalDragCancel: () {
                          setState(() {
                            _isDragging = false;
                            _lastHapticPage = -1;
                          });
                          _triggerVisibility();
                        },
                      ),
                    ),

                    // Beautiful Floating Page Pill on top of the scrollbar thumb
                    Positioned(
                      left: pillLeft,
                      bottom: thumbHeight + 6,
                      child: IgnorePointer(
                        child: Container(
                          width: pillWidth,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isDark
                                  ? [
                                      const Color(0xFF2A531D),
                                      const Color(0xFF16251C),
                                    ]
                                  : [
                                      const Color(0xFF2A531D),
                                      const Color(0xFF1E3A15),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFd1ffbe).withValues(alpha: 0.65),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A531D).withValues(
                                  alpha: widget.isDark ? 0.40 : 0.20,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                FlutterIslamicIcons.quran2,
                                size: 12,
                                color: Color(0xFFd1ffbe),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$displayPageNum / ${widget.totalPages}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Sleek bottom-docked handle with elegant left-right drag icon (touching bottom edge flush)
                    Positioned(
                      left: thumbLeft,
                      bottom: 0, // completely touches the bottom edge
                      child: IgnorePointer(
                        child: Container(
                          width: thumbWidth,
                          height: thumbHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDragging
                                  ? [
                                      const Color(0xFF84CC16),
                                      const Color(0xFF2A531D),
                                    ]
                                  : (widget.isDark
                                      ? [
                                          const Color(0xFF2A531D),
                                          const Color(0xFF1B3623),
                                        ]
                                      : [
                                          const Color(0xFF669f1d),
                                          const Color(0xFF2A531D),
                                        ]),
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(13),
                              topRight: Radius.circular(13),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A531D).withValues(
                                  alpha: _isDragging ? 0.20 : 0.08,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, -1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Icon(
                                Icons.unfold_more_rounded,
                                color: Colors.white,
                                size: 22,
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
          ),
        );
      },
    );
  }
}
