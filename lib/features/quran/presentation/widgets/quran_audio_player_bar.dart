import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_typography.dart';
import '../../services/quran_audio_service.dart';

/// Compact, floating, 100% overflow-proof Audio Player Bar matching Asma Ul Husna screen.
class QuranAudioPlayerBar extends StatelessWidget {
  final QuranAudioController quranAudio;
  final bool isDark;

  const QuranAudioPlayerBar({
    super.key,
    required this.quranAudio,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ayah = quranAudio.currentAyah;
    final totalAyahs = quranAudio.playlist.length;
    final currentAyahNumber = quranAudio.currentIndex + 1;
    final double sliderValue =
        (currentAyahNumber.toDouble()).clamp(1.0, totalAyahs > 0 ? totalAyahs.toDouble() : 1.0);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 4
              : 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF1E3A1A), const Color(0xFF0F230D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Ayah Number Badge + Title / Subtitle + Arabic Text snippet + Close
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${ayah?.numberInSurah ?? currentAyahNumber}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ayah != null
                                ? 'Ayah ${ayah.numberInSurah} of $totalAyahs'
                                : quranAudio.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            quranAudio.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (ayah != null && ayah.displayArabicText.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            ayah.displayArabicText,
                            textDirection: TextDirection.rtl,
                            style: AppTypography.arabicHeader(
                              color: const Color(0xFF4ADE80),
                              fontSize: 18,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 18,
                      ),
                      onPressed: quranAudio.stop,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),

              // Progress Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4.5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 8,
                    ),
                    activeTrackColor: const Color(0xFF4ADE80),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 1.0,
                    max: totalAyahs > 0 ? totalAyahs.toDouble() : 1.0,
                    divisions: totalAyahs > 1 ? totalAyahs - 1 : 1,
                    onChanged: (val) {
                      final targetIndex = val.toInt() - 1;
                      if (targetIndex >= 0 &&
                          targetIndex < totalAyahs &&
                          targetIndex != quranAudio.currentIndex) {
                        quranAudio.playIndex(targetIndex);
                      }
                    },
                  ),
                ),
              ),

              // Controls row: Speed Selector, Previous, Play/Pause, Next, Single-Verse Repeat
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Playback speed pill
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final speeds = [1.0, 1.25, 1.5, 2.0];
                          final currIndex = speeds.indexOf(quranAudio.speed);
                          final nextSpeed =
                              speeds[(currIndex + 1) % speeds.length];
                          quranAudio.setSpeed(nextSpeed);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            '${quranAudio.speed}x',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center Playback Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: quranAudio.currentIndex > 0
                              ? () => quranAudio.playPrevious()
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: quranAudio.togglePlayPause,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                ),
                              ),
                              child: Icon(
                                quranAudio.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: quranAudio.currentIndex < totalAyahs - 1
                            ? () => quranAudio.playNext()
                            : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),

                    // Repeat Single Ayah Mode Toggle
                    IconButton(
                      icon: Icon(
                        quranAudio.isLoopSingle
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: quranAudio.isLoopSingle
                            ? const Color(0xFF4ADE80)
                            : Colors.white60,
                        size: 20,
                      ),
                      onPressed: quranAudio.toggleLoopSingle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Repeat Ayah',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
