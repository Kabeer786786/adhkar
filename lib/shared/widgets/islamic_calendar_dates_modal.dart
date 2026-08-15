import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/hijri_service.dart';
import '../providers/app_providers.dart';

class IslamicCalendarDatesModal extends ConsumerWidget {
  const IslamicCalendarDatesModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const IslamicCalendarDatesModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final todayHijri = ref.watch(todayHijriProvider).value;
    final location = ref.watch(currentLocationProvider).value;
    final isSubcontinent = HijriService.isChandKiTarikhRegion(location?.country);

    final events = [
      {
        'hijri': '1 Muharram',
        'title': 'Islamic New Year',
        'desc': 'Beginning of the Hijri year',
        'icon': Icons.brightness_3_rounded,
        'color': const Color(0xFFD97724),
      },
      {
        'hijri': '10 Muharram',
        'title': 'Day of Ashura',
        'desc': 'Recommended Sunnah fasting day',
        'icon': Icons.water_drop_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'hijri': '12 Rabi\' al-Awwal',
        'title': 'Mawlid an-Nabi (ﷺ)',
        'desc': 'Birth of Prophet Muhammad (ﷺ)',
        'icon': Icons.star_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'hijri': '27 Rajab',
        'title': 'Isra & Mi\'raj',
        'desc': 'Miraculous Night Journey & Ascension',
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFF9333EA),
      },
      {
        'hijri': '15 Sha\'ban',
        'title': 'Shab-e-Baraat',
        'desc': 'Night of Forgiveness & Blessings',
        'icon': Icons.nightlight_round,
        'color': const Color(0xFFEC4899),
      },
      {
        'hijri': '1 Ramadan',
        'title': 'Start of Holy Ramadan',
        'desc': 'Obligatory month of fasting & Quran',
        'icon': Icons.mosque_rounded,
        'color': const Color(0xFF15803D),
      },
      {
        'hijri': '27 Ramadan',
        'title': 'Laylat al-Qadr',
        'desc': 'Night of Power (Better than 1000 months)',
        'icon': Icons.auto_awesome_sharp,
        'color': const Color(0xFFD97724),
      },
      {
        'hijri': '1 Shawwal',
        'title': 'Eid al-Fitr',
        'desc': 'Blessed Festival of Breaking Fast',
        'icon': Icons.celebration_rounded,
        'color': const Color(0xFF16A34A),
      },
      {
        'hijri': '9 Dhul-Hijjah',
        'title': 'Day of Arafah',
        'desc': 'Pinnacle day of Hajj & Sunnah fast',
        'icon': Icons.landscape_rounded,
        'color': const Color(0xFFB45309),
      },
      {
        'hijri': '10 Dhul-Hijjah',
        'title': 'Eid al-Adha',
        'desc': 'Feast of Sacrifice',
        'icon': Icons.card_giftcard_rounded,
        'color': const Color(0xFFD97724),
      },
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle bar
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Text(
            'ISLAMIC CALENDAR DATES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? Colors.white : const Color(0xFF2A531D),
            ),
          ),
          const SizedBox(height: 4),
          if (todayHijri != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2A531D).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Today: ${todayHijri.formatted}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Scrollable Events List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = events[index];
                final iconColor = item['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF23322B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: GoogleFonts.lexend(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item['hijri'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Regional Moon Sighting Disclaimer Note at Bottom
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSubcontinent
                  ? const Color(0xFFD97724).withValues(alpha: 0.1)
                  : const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSubcontinent
                    ? const Color(0xFFD97724).withValues(alpha: 0.3)
                    : const Color(0xFF2563EB).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: isSubcontinent ? const Color(0xFFD97724) : const Color(0xFF2563EB),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSubcontinent
                        ? 'Note: We have adjusted the Hijri dates for India, Pakistan, & Bangladesh based on local moon sighting. Hijri dates may vary by ±1 day.'
                        : 'Note: Hijri dates follow standard global astronomical calculation. Hijri dates may vary by ±1 day based on local moon sighting.',
                    style: GoogleFonts.lexend(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF23322B) : const Color(0xFFE8F4E5),
                foregroundColor: const Color(0xFF2A531D),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
