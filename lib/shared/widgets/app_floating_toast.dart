import 'package:flutter/material.dart';

class AppFloatingToast {
  static OverlayEntry? _activeOverlay;

  static void show(
    BuildContext context, {
    required String message,
    required bool isAdded,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    double bottomOffset = 70.0,
  }) {
    _activeOverlay?.remove();
    _activeOverlay = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final iconData = icon ??
        (isAdded
            ? Icons.check_circle_rounded
            : Icons.remove_circle_outline_rounded);

    final bgColor = isAdded ? const Color(0xFF2A531D) : const Color(0xFF334155);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottomOffset,
        left: 30,
        right: 30,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 180),
              builder: (context, val, child) => Transform.scale(
                scale: 0.9 + (0.1 * val),
                child: Opacity(opacity: val, child: child),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _activeOverlay = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (_activeOverlay == entry) {
        entry.remove();
        _activeOverlay = null;
      }
    });
  }

  static void showAdded(
    BuildContext context, {
    String message = 'Added',
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      isAdded: true,
      icon: icon,
      duration: duration,
    );
  }

  static void showRemoved(
    BuildContext context, {
    String message = 'Removed',
    IconData icon = Icons.remove_circle_outline_rounded,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      isAdded: false,
      icon: icon,
      duration: duration,
    );
  }
}
