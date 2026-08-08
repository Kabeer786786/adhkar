import 'package:flutter/material.dart';
import '../core/extensions/context_extensions.dart';

class AppActionMenuItem<T> {
  final T value;
  final String title;
  final IconData icon;
  final Color? color;
  final bool isDestructive;

  const AppActionMenuItem({
    required this.value,
    required this.title,
    required this.icon,
    this.color,
    this.isDestructive = false,
  });
}

class AppActionPopupMenu<T> extends StatelessWidget {
  final List<AppActionMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final Color? iconColor;
  final String? tooltip;
  final double iconSize;

  const AppActionPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon = Icons.more_vert_rounded,
    this.iconColor,
    this.tooltip = 'Options',
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = const Color(0xFF2A531D);

    return PopupMenuButton<T>(
      onSelected: onSelected,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? (isDark ? Colors.white70 : primaryColor),
      ),
      elevation: 6,
      color: isDark ? const Color(0xFF192520) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      itemBuilder: (context) {
        return items.map((item) {
          final itemColor = item.color ??
              (item.isDestructive
                  ? Colors.redAccent
                  : (isDark ? Colors.white : const Color(0xFF1F2937)));

          return PopupMenuItem<T>(
            value: item.value,
            height: 42,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isDestructive
                      ? Colors.redAccent
                      : (item.color ?? (isDark ? const Color(0xFFA3E635) : primaryColor)),
                ),
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
