import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

class M3Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const M3Card({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.color,
    this.gradient,
    this.borderRadius = 24.0,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (context.isDarkMode
            ? context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : const Color(0xFFE7F6E3));

    final effectiveBorder = border ??
        Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFC8E6C9),
          width: 1,
        );

    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
 
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ), 
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap, 
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding!,
            child: child,
          ),
        ),
      ),
    );
  }
}

