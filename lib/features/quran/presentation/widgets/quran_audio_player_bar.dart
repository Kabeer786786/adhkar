import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_typography.dart';
import '../../services/quran_audio_service.dart';

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
        (currentAyahNumber.toDouble()).clamp(1.0, totalAyahs.toDouble());

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A12).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ayah?.numberInSurah ?? currentAyahNumber}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ayah != null
                              ? 'Ayah ${ayah.numberInSurah} of $totalAyahs'
                              : quranAudio.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          quranAudio.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (ayah != null && ayah.displayArabicText.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        ayah.displayArabicText,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.arabicHeader(
                          color: const Color(0xFF4ADE80),
                          fontSize: 20,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                    ),
                    onPressed: quranAudio.stop,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Row(
                children: [
                  // Playback speed toggle on bottom-left
                  InkWell(
                    onTap: () {
                      final speeds = [1.0, 1.25, 1.5, 2.0];
                      final currIndex = speeds.indexOf(quranAudio.speed);
                      final nextSpeed =
                          speeds[(currIndex + 1) % speeds.length];
                      quranAudio.setSpeed(nextSpeed);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF22C55E,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(
                            0xFF4ADE80,
                          ).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${quranAudio.speed}x',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ),

                  // Centered Playback Controls
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: quranAudio.currentIndex > 0
                              ? () => quranAudio.playPrevious()
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: quranAudio.togglePlayPause,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 52,
                              height: 52,
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
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed:
                              quranAudio.currentIndex < totalAyahs - 1
                                  ? () => quranAudio.playNext()
                                  : null,
                        ),
                      ],
                    ),
                  ),

                  // Right placeholder to balance layout
                  const SizedBox(width: 42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
