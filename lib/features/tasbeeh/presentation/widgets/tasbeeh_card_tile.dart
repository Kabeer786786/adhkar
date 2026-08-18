import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/models/tasbeeh_item.dart';

class TasbeehCardTile extends StatelessWidget {
  final TasbeehItem item;
  final int currentCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TasbeehCardTile({
    super.key,
    required this.item,
    required this.currentCount,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = item.targetGoal > 0
        ? (currentCount / item.targetGoal).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = currentCount >= item.targetGoal;

    final cardBgColor = context.isDarkMode
        ? const Color(0xFF1E2923)
        : const Color(0xFFF9F9F9);

    final borderColor = isCompleted
        ? item.color.withValues(alpha: 0.6)
        : (context.isDarkMode ? Colors.white10 : const Color(0xFFE2ECE0));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isCompleted ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Side (Whole part): Arabic & English Transliteration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic Text
                      Text(
                        item.textAr,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                          color: context.isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E3816),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // English Transliteration
                      Text(
                        item.textEn,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: item.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // if (item.effectiveTranslation.isNotEmpty) ...[
                      //   const SizedBox(height: 3),
                      //   Text(
                      //     item.effectiveTranslation,
                      //     style: GoogleFonts.lexend(
                      //       fontSize: 12.5,
                      //       fontWeight: FontWeight.w400,
                      //       fontStyle: FontStyle.italic,
                      //       color: context.colorScheme.onSurfaceVariant,
                      //     ),
                      //     maxLines: 2,
                      //     overflow: TextOverflow.ellipsis,
                      //   ),
                      // ],
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right Side: Circular Progress showing count completed
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4.5,
                        backgroundColor: item.color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: item.color,
                          )
                        else ...[
                          Text(
                            '$currentCount',
                            style: GoogleFonts.oxanium(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '/${item.targetGoal}',
                            style: GoogleFonts.oxanium(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
