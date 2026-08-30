import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingDraggableScrollbar extends StatefulWidget {
  final ScrollController scrollController;
  final int itemCount;
  final bool isDark;
  final List<dynamic>? items;
  final int? selectedTab;
  final dynamic arabicFont;

  const FloatingDraggableScrollbar({
    super.key,
    required this.scrollController,
    required this.itemCount,
    required this.isDark,
    this.items,
    this.selectedTab,
    this.arabicFont, 
  });

  @override
  State<FloatingDraggableScrollbar> createState() =>
      _FloatingDraggableScrollbarState();
}

class _FloatingDraggableScrollbarState
    extends State<FloatingDraggableScrollbar> {
  bool _isVisible = false;
  bool _isDragging = false;
  double _progress = 0.0;
  int _lastHapticIndex = -1;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant FloatingDraggableScrollbar oldWidget) {
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
    super.dispose();
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

  void _onScroll() {
    if (!mounted || _isDragging) return;
    if (widget.scrollController.hasClients) {
      final max = widget.scrollController.position.maxScrollExtent;
      final offset = widget.scrollController.offset;
      final p = max > 0 ? (offset / max).clamp(0.0, 1.0) : 0.0;

      _triggerVisibility();

      if ((p - _progress).abs() > 0.001) {
        setState(() {
          _progress = p;
        });
      }
    }
  }

  void _updateDrag(double localY, double availableHeight) {
    if (availableHeight <= 0 || widget.itemCount <= 0) return;
    final clampedY = localY.clamp(0.0, availableHeight);
    final p = (clampedY / availableHeight).clamp(0.0, 1.0);
    final targetIdx =
        ((widget.itemCount - 1) * p).round().clamp(0, widget.itemCount - 1);

    if (targetIdx != _lastHapticIndex) {
      _lastHapticIndex = targetIdx;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _progress = p;
    });

    if (widget.scrollController.hasClients) {
      final max = widget.scrollController.position.maxScrollExtent;
      widget.scrollController.jumpTo((p * max).clamp(0.0, max));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 2) return const SizedBox.shrink();

    // Height 36.0, compact sleek width ~22px
    const double thumbHeight = 36.0; 

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableTravel =
            (constraints.maxHeight - thumbHeight).clamp(1.0, double.infinity);
        final double thumbTop =
            (_progress * availableTravel).clamp(0.0, availableTravel);

        return RepaintBoundary(
          child: AnimatedSlide(
            offset: _isVisible ? Offset.zero : const Offset(0.95, 0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
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
                        setState(() => _isDragging = true);
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
                        setState(() {
                          _isDragging = false;
                          _lastHapticIndex = -1;
                        });
                        _triggerVisibility();
                      },
                      onVerticalDragCancel: () {
                        setState(() {
                          _isDragging = false;
                          _lastHapticIndex = -1;
                        });
                        _triggerVisibility();
                      },
                    ),
                  ),

                  // Sleek right-docked handle with elegant up-down drag icon
                  Positioned(
                    top: thumbTop,
                    right: 0, // completely touches the right edge
                    child: IgnorePointer(
                      child: Container( 
                        height: thumbHeight,
                        width: 30,
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
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                         borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(13),
                            bottomLeft: Radius.circular(13),
                            topRight: Radius.zero,
                            bottomRight: Radius.zero,
                          ),
                          
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2A531D).withValues(
                                alpha: _isDragging ? 0.20 : 0.08,
                              ),
                              blurRadius: _isDragging ? 4 : 2,
                              offset: const Offset(-1, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.unfold_more_rounded,
                            color: Colors.white,
                            size: 22,
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
