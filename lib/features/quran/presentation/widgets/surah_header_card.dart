import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/juz_model.dart';
import '../../data/surah_model.dart';
import '../../services/quran_audio_service.dart';

class SurahHeaderCard extends StatelessWidget {
  final SurahModel currentSurah;
  final List<AyahModel> ayahs;
  final bool isDark;
  final bool isJuzMode;
  final JuzModel? currentJuz;
  final IconData revelationIcon;
  final dynamic arabicFont;
  final QuranAudioController quranAudio;
  final bool isDownloaded; 
  final VoidCallback onPlayPlaylist;
  final VoidCallback onDownloadTap;

  const SurahHeaderCard({
    super.key,
    required this.currentSurah,
    required this.ayahs,
    required this.isDark,
    required this.isJuzMode,
    this.currentJuz,
    required this.revelationIcon,
    required this.arabicFont,
    required this.quranAudio,
    required this.isDownloaded,
    required this.onPlayPlaylist,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    final String transliteration = isJuzMode
        ? currentJuz!.nameEnglish
        : currentSurah.nameEnglish;

    final String arabicName = isJuzMode
        ? currentJuz!.nameArabic
        : currentSurah.nameArabic;

    final int startJuz = ayahs.isNotEmpty ? ayahs.first.juz : 1;
    final int endJuz = ayahs.isNotEmpty ? ayahs.last.juz : 1;

    final bool isPlayingThisPlaylist =
        quranAudio.currentIndex >= 0 && quranAudio.isPlaying;

    final bool hasBismillah = isJuzMode ? false : currentSurah.bismillahPre;

    final int itemNumber =
        isJuzMode ? (currentJuz?.number ?? 1) : currentSurah.number;
    final String englishTitle = isJuzMode
        ? 'Juz $itemNumber - $transliteration'
        : '$itemNumber. $transliteration';
    final String subtitle = isJuzMode
        ? (currentJuz?.surahRange ?? '')
        : currentSurah.nameTranslation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF669f1d), const Color(0xFF2A531D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFd1ffbe).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A531D).withValues(
                  alpha: isDark ? 0.35 : 0.25,
                ),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tag Row (Matching Recent Card)
              Row(
                children: [
                  const Icon(
                    FlutterIslamicIcons.quran2,
                    size: 14,
                    color: Color(0xFFd1ffbe),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isJuzMode ? 'JUZ DETAILS' : 'SURAH DETAILS',
                    style: const TextStyle(
                      color: Color(0xFFd1ffbe),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 1: Left (Item Number & Transliteration + Translation Meaning) & Right (Arabic Name)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          englishTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    arabicName,
                    textDirection: TextDirection.rtl,
                    style: AppTypography.arabicHeader(
                      arabicFont: arabicFont,
                      fontSize: 28,
                      color: const Color(0xFFd1ffbe),
                      height: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),

              // Row 2: Badges on Left & Audio / Download Actions on Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Side: Metadata Badges
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!isJuzMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentSurah.revelationType.toLowerCase() ==
                                          'meccan'
                                      ? FlutterIslamicIcons.solidKaaba
                                      : FlutterIslamicIcons.solidMosque,
                                  size: 11,
                                  color: const Color(0xFFd1ffbe),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentSurah.revelationType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isJuzMode
                                ? '${ayahs.length} Ayahs'
                                : '${currentSurah.verseCount} Ayahs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            startJuz == endJuz
                                ? 'Juz $startJuz'
                                : 'Juz $startJuz-$endJuz',
                            style: const TextStyle(
                              color: Color(0xFFd1ffbe),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right Side: Offline Download & Play All Audio Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                        onPressed: onDownloadTap,
                        icon: Icon(
                          isDownloaded
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                          color: isDownloaded
                              ? const Color(0xFFA3E635)
                              : Colors.white70,
                          size: 20,
                        ),
                        tooltip: isDownloaded
                            ? 'Audio downloaded for offline reading'
                            : 'Download all audio for offline reading',
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPlayingThisPlaylist
                              ? const Color(0xFFd1ffbe)
                              : const Color(0xFFA3E635),
                          foregroundColor: const Color(0xFF1A3512),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onPlayPlaylist,
                        icon: Icon(
                          isPlayingThisPlaylist
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isPlayingThisPlaylist ? 'Pause' : 'Play All',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Beautiful Calligraphic Bismillah Card
        if (hasBismillah) ...[
          const SizedBox(height: 18),
          Center(
            child: Text(
              "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ",
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppTypography.arabicHeader(
                arabicFont: arabicFont,
                fontSize: 24,
                color: isDark
                    ? const Color(0xFFA3E635)
                    : const Color(0xFF2A531D),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
