import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFloatingToast {
  static OverlayEntry? _activeOverlay;
  static Timer? _activeTimer;

  /// Strips leading emojis or common emoji glyphs from the message
  static String _stripLeadingEmojis(String text) {
    // Matches leading emoji glyphs, symbols, pictographs and trailing spaces
    final emojiRegex = RegExp(
      r'^[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E0}-\u{1F1FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{200D}\s]+',
      unicode: true,
    );
    final cleaned = text.replaceFirst(emojiRegex, '').trim();
    return cleaned.isNotEmpty ? cleaned : text;
  }

  /// Automatically derives an appropriate icon and accent color based on message keywords
  static (IconData, Color) _resolveIconAndColor({
    String? message,
    bool? isAdded,
    bool? isSuccess,
    IconData? explicitIcon,
    Color? explicitIconColor,
  }) {
    if (explicitIcon != null) {
      return (
        explicitIcon,
        explicitIconColor ?? const Color(0xFF4ADE80),
      );
    }

    final lower = (message ?? '').toLowerCase();

    // Positive / Added / Enabled / Saved / Activated
    if (isSuccess == true ||
        isAdded == true ||
        lower.contains('activat') && !lower.contains('deactivat') ||
        lower.contains('enable') && !lower.contains('disable') ||
        lower.contains('added') ||
        lower.contains('saved') ||
        lower.contains('success') ||
        lower.contains('completed') ||
        lower.contains('download') ||
        lower.contains('updated')) {
      return (
        Icons.check_circle_rounded,
        explicitIconColor ?? const Color(0xFF4ADE80), // Vibrant emerald
      );
    }

    // Deactivated / Disabled / Paused / Turned off
    if (lower.contains('deactivat') ||
        lower.contains('disable') ||
        lower.contains('paused') ||
        lower.contains('turned off') ||
        lower.contains('inactive')) {
      return (
        Icons.pause_circle_rounded,
        explicitIconColor ?? const Color(0xFF94A3B8), // Cool slate
      );
    }

    // Removed / Deleted / Cleared
    if (isAdded == false ||
        lower.contains('remove') ||
        lower.contains('delete') ||
        lower.contains('cleared')) {
      return (
        Icons.delete_outline_rounded,
        explicitIconColor ?? const Color(0xFFF87171), // Soft coral red
      );
    }

    // Copied / Clipboard
    if (lower.contains('copi') || lower.contains('clipboard')) {
      return (
        Icons.copy_rounded,
        explicitIconColor ?? const Color(0xFF38BDF8), // Cyan / Sky blue
      );
    }

    // Bookmark / Flag / Stop point
    if (lower.contains('bookmark')) {
      return (
        Icons.bookmark_rounded,
        explicitIconColor ?? const Color(0xFFFBBF24), // Amber
      );
    }
    if (lower.contains('stop point') || lower.contains('jump')) {
      return (
        Icons.flag_rounded,
        explicitIconColor ?? const Color(0xFFFBBF24), // Amber
      );
    }

    // Location / GPS
    if (lower.contains('location') || lower.contains('gps')) {
      return (
        Icons.location_on_rounded,
        explicitIconColor ?? const Color(0xFF38BDF8),
      );
    }

    // Error / Failed / Invalid / Not found
    if (isSuccess == false ||
        lower.contains('fail') ||
        lower.contains('error') ||
        lower.contains('invalid') ||
        lower.contains('not found') ||
        lower.contains('enter a valid')) {
      return (
        Icons.error_outline_rounded,
        explicitIconColor ?? const Color(0xFFEF4444), // Bright red
      );
    }

    // Default info
    return (
      Icons.info_outline_rounded,
      explicitIconColor ?? const Color(0xFF38BDF8),
    );
  }

  /// Instantly dismisses any existing toast and immediately shows the new bottom toast.
  /// Persists for at most 2 seconds by default.
  static void show(
    BuildContext context, {
    required String message,
    bool? isAdded,
    bool? isSuccess,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    // 1. Instantly cancel active timer and remove previous overlay with zero delay
    _activeTimer?.cancel();
    _activeTimer = null;
    if (_activeOverlay != null) {
      _activeOverlay?.remove();
      _activeOverlay = null;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    // Clean emojis from text and resolve icon + color
    final cleanMessage = _stripLeadingEmojis(message);
    final (resolvedIcon, resolvedIconColor) = _resolveIconAndColor(
      message: cleanMessage,
      isAdded: isAdded,
      isSuccess: isSuccess,
      explicitIcon: icon,
      explicitIconColor: iconColor,
    );

    // Compute bottom position above the navigation bar / safe insets
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final targetBottom = bottomOffset ?? (bottomInset + 76.0);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: targetBottom,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Transform.translate(
                offset: Offset(0, 12 * (1 - val)),
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      resolvedIcon,
                      color: resolvedIconColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        cleanMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
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

    // Auto dismiss after duration (max 2s)
    _activeTimer = Timer(duration, () {
      if (_activeOverlay == entry) {
        entry.remove();
        _activeOverlay = null;
        _activeTimer = null;
      }
    });
  }

  /// Convenience helper for added items
  static void showAdded(
    BuildContext context, {
    String message = 'Added',
    IconData? icon,
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      isAdded: true,
      icon: icon,
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Convenience helper for removed items
  static void showRemoved(
    BuildContext context, {
    String message = 'Removed',
    IconData? icon,
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      isAdded: false,
      icon: icon,
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Convenience helper for toggling on / activated
  static void showEnabled(
    BuildContext context, {
    String message = 'Activated',
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      isSuccess: true,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF4ADE80),
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Convenience helper for toggling off / deactivated
  static void showDisabled(
    BuildContext context, {
    String message = 'Deactivated',
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      isSuccess: false,
      icon: Icons.pause_circle_rounded,
      iconColor: const Color(0xFF94A3B8),
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Convenience helper for success messages
  static void showSuccess(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      isSuccess: true,
      icon: icon ?? Icons.check_circle_rounded,
      iconColor: iconColor ?? const Color(0xFF4ADE80),
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Convenience helper for error messages
  static void showError(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2000),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      isSuccess: false,
      icon: icon ?? Icons.error_outline_rounded,
      iconColor: iconColor ?? const Color(0xFFEF4444),
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Convenience helper for informational messages
  static void showInfo(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 1800),
    double? bottomOffset,
  }) {
    show(
      context,
      message: message,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
      bottomOffset: bottomOffset,
    );
  }

  /// Displays a premium bottom pill toast indicating double-tap back to exit with the round app logo.
  static void showExitToast(
    BuildContext context, {
    String message = 'Press back again to exit Adhkar',
    Duration duration = const Duration(milliseconds: 2000),
    double? bottomOffset,
  }) {
    // 1. Instantly cancel active timer and remove previous overlay
    _activeTimer?.cancel();
    _activeTimer = null;
    if (_activeOverlay != null) {
      _activeOverlay?.remove();
      _activeOverlay = null;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final targetBottom = bottomOffset ?? (bottomInset + 76.0);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: targetBottom,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              builder: (context, val, child) => Transform.translate(
                offset: Offset(0, 14 * (1 - val)),
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.75),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.spa_rounded,
                            size: 16,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
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

    _activeTimer = Timer(duration, () {
      if (_activeOverlay == entry) {
        entry.remove();
        _activeOverlay = null;
        _activeTimer = null;
      }
    });
  }
}
