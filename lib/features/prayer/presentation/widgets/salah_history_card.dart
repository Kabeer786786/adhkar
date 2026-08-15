import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/hijri_date_helper.dart';
import 'salah_3d_circular_progress.dart';

class SalahHistoryCard extends StatelessWidget {
  final DateTime date;
  final int completedFarz;
  final int totalFarz;
  final int completedWajib;
  final int totalWajib;
  final int completedSunnat;
  final int totalSunnat;
  final int completedNafeel;
  final int totalNafeel;
  final String? hijriDate;
  final VoidCallback? onTap;

  const SalahHistoryCard({
    super.key,
    required this.date,
    this.hijriDate,
    required this.completedFarz,
    this.totalFarz = 5,
    required this.completedWajib,
    this.totalWajib = 1,
    required this.completedSunnat,
    this.totalSunnat = 20,
    required this.completedNafeel,
    this.totalNafeel = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    String gregorianStr;
    if (isToday) {
      gregorianStr = 'Today, ${_formatDayMonth(date)}';
    }  else {
      gregorianStr = _formatFullDate(date);
    }

    final hijriStr =
        hijriDate ?? HijriDateHelper.formatHijri(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1A2818)
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Gregorian Date Left | Hijri Date Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      gregorianStr,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      hijriStr,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        color: context.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 4 Circular Gauges Row (Farz, Wajib, Sunnat, Nafeel)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Salah3DCircularProgress(
                      label: 'Farz',
                      completed: completedFarz,
                      total: totalFarz,
                      primaryColor: const Color(0xFF10B981),
                      secondaryColor: const Color(0xFF059669),
                    ),
                    Salah3DCircularProgress(
                      label: 'Wajib',
                      completed: completedWajib,
                      total: totalWajib,
                      primaryColor: const Color(0xFF63C5F2),
                      secondaryColor: const Color(0xFF477FE6),
                    ),
                    Salah3DCircularProgress(
                      label: 'Sunnat',
                      completed: completedSunnat,
                      total: totalSunnat,
                      primaryColor: const Color(0xFFC47BED),
                      secondaryColor: const Color(0xFFA836E2),
                    ),
                    Salah3DCircularProgress(
                      label: 'Nafeel',
                      completed: completedNafeel,
                      total: totalNafeel,
                      primaryColor: const Color(0xFFECAD56),
                      secondaryColor: const Color(0xFFB19030),
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

  String _formatDayMonth(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatFullDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
