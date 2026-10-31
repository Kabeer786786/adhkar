import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/tasbeeh_item.dart';

class TasbeehDescriptionModal extends StatelessWidget {
  final TasbeehItem item;

  const TasbeehDescriptionModal({super.key, required this.item});

  static void show(BuildContext context, TasbeehItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TasbeehDescriptionModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final itemColor = (isDark && item.color.value == 0xFF2A531D)
        ? const Color(0xFF18A74C)
        : item.color;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3F3F46)
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Row with Title & Theme Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 22,
                  color: itemColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.textEn,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: itemColor,
                      ),
                    ),
                    Text(
                      item.textAr,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabicBody(
                        fontSize: 22,
                        height: 1.7,
                        color: isDark ? Colors.white : const Color(0xFF1E3816),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Divider(
            height: 1,
            color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),

          // Virtues & Meaning Section Header
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFF86EFAC)
                    : context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'WHY RECITE THIS?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark
                      ? const Color(0xFF86EFAC)
                      : context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Full Description Text Display
          Text(
            item.description.isNotEmpty
                ? item.description
                : 'No specific virtues recorded for this custom Tasbeeh. Recite with presence of heart and devotion.',
            style: GoogleFonts.lexend(
              fontSize: 14.5,
              height: 1.55,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // Target Goal Badge Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F0F12)
                  : itemColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF27272A)
                    : itemColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Target:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: itemColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.targetGoal} Times',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark && item.color.value == 0xFF2A531D
                          ? const Color(0xFF0F0F12)
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: itemColor,
                foregroundColor: isDark && item.color.value == 0xFF2A531D
                    ? const Color(0xFF0F0F12)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
