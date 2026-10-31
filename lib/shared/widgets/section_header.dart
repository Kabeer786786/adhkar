import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onActionTap;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.white70 : context.colorScheme.onSurfaceVariant;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actionText != null) ...[
                      Text(
                        actionText!,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE7F6E3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF2A531D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
