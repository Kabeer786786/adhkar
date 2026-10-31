import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/data/daily_ayah_model.dart';
import '../../../quran/presentation/providers/daily_ayah_provider.dart';

/// Card widget displaying the Daily Quran Ayah on the Home Screen.
/// Displays Arabic text, English translation, and single line citation:
/// Quran • SurahEnglish (SurahArabic) surahNo:verseNo
class DailyAyahCard extends ConsumerWidget {
  const DailyAyahCard({super.key});

  void _navigateToSurah(BuildContext context, DailyAyahModel ayah) {
    context.push(
      '/quran/surah?num=${ayah.surahNumber}&name=${Uri.encodeComponent(ayah.surahEnglishName)}&startAyah=${ayah.numberInSurah}&juz=${ayah.juz}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(dailyAyahProvider);

    return ayahAsync.when(
      data: (ayah) => _buildCard(context, ayah),
      loading: () {
        final cached = ref.read(dailyAyahServiceProvider).getCachedAyah();
        return _buildCard(context, cached ?? DailyAyahModel.defaultAyah);
      },
      error: (error, stackTrace) => _buildCard(context, DailyAyahModel.defaultAyah),
    );
  }

  Widget _buildCard(BuildContext context, DailyAyahModel ayah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3FAF2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _navigateToSurah(context, ayah),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Centered Arabic Quote
                Text(
                  ayah.arabicText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.arabicHeader(
                    fontSize: 22,
                    height: 1.8,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1A3512),
                  ),
                ),
                const SizedBox(height: 12),

                // Translation below it
                Text(
                  '"${ayah.translationText}"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF2A531D),
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom Left Corner: Single line citation
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FlutterIslamicIcons.quran2,
                        size: 15,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF8C6D53),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Quran • ${ayah.surahEnglishName} (${ayah.surahName}) ${ayah.surahNumber}:${ayah.numberInSurah}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF8C6D53),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
