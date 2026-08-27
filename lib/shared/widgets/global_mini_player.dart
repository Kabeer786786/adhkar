import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions/context_extensions.dart';
import '../../features/asma_ul_husna/services/asma_audio_service.dart';
import '../../features/quran/services/quran_audio_service.dart';

class GlobalMiniPlayer extends ConsumerWidget {
  final int? currentBranchIndex;

  const GlobalMiniPlayer({super.key, this.currentBranchIndex});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranAudio = ref.watch(quranAudioProvider);
    final asmaAudio = ref.watch(asmaAudioProvider);

    final bool isQuranActive = quranAudio.currentIndex >= 0;
    final bool isAsmaActive = !isQuranActive && asmaAudio.currentIndex >= 0;

    if (!isQuranActive && !isAsmaActive) {
      return const SizedBox.shrink();
    }

    // Quran audio should ONLY show on the Quran screen (branch index 1)
    if (isQuranActive && currentBranchIndex != null && currentBranchIndex != 1) {
      return const SizedBox.shrink();
    }

    final isDark = context.isDarkMode;
    final primaryColor = const Color(0xFF2A531D);
    final accentGreen = const Color(0xFF4ADE80);

    final String title;
    final String subtitle;
    final bool isPlaying;
    final bool isBuffering;
    final Duration position;
    final Duration duration;

    final VoidCallback onPrevious;
    final VoidCallback onPlayPause;
    final VoidCallback onNext;
    final VoidCallback onClose;
    final VoidCallback onTapCard;
    final ValueChanged<double> onSeek;

    if (isQuranActive) {
      final surahName = quranAudio.title.isNotEmpty ? quranAudio.title : 'Quran';
      final currentAyah = quranAudio.currentAyah;
      title = '$surahName ${currentAyah != null ? "• Verse ${currentAyah.numberInSurah}" : ""}';
      subtitle = 'The Noble Qur\'an Recitation';
      isPlaying = quranAudio.isPlaying;
      isBuffering = quranAudio.isBuffering;
      position = quranAudio.position;
      duration = quranAudio.duration;

      onPrevious = quranAudio.playPrevious;
      onPlayPause = quranAudio.togglePlayPause;
      onNext = quranAudio.playNext;
      onClose = quranAudio.stop;
      onSeek = (val) => quranAudio.seek(Duration(milliseconds: val.toInt()));
      onTapCard = () {
        final surahNum = quranAudio.surahNumber ?? 1;
        final name = Uri.encodeComponent(surahName);
        context.push('/quran/surah?num=$surahNum&name=$name');
      };
    } else {
      final nameItem = asmaAudio.currentName;
      title = nameItem != null
          ? '${nameItem.number}. ${nameItem.name} (${nameItem.transliteration})'
          : 'Asma ul Husna';
      subtitle = nameItem?.meaning ?? '99 Names of Allah';
      isPlaying = asmaAudio.isPlaying;
      isBuffering = asmaAudio.isBuffering;
      position = asmaAudio.position;
      duration = asmaAudio.duration;

      onPrevious = asmaAudio.playPrevious;
      onPlayPause = asmaAudio.togglePlayPause;
      onNext = asmaAudio.playNext;
      onClose = asmaAudio.stop;
      onSeek = (val) => asmaAudio.seek(Duration(milliseconds: val.toInt()));
      onTapCard = () {
        context.push('/asma-ul-husna');
      };
    }

    final double maxDurationMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final double currentPositionMs = position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16251C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2A531D) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTapCard,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Artwork Thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E3A27), const Color(0xFF0F2317)]
                              : [const Color(0xFFE8F4E5), const Color(0xFFC8E6C9)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.music_note_rounded,
                            color: isDark ? accentGreen : primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Subtitle Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.lexend(
                              fontSize: 11.5,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Player Controls (Left Arrow, Play/Pause, Right Arrow, Close)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: onPrevious,
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: isDark ? Colors.white : primaryColor,
                            size: 26,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          tooltip: 'Previous',
                        ),
                        isBuffering
                            ? Container(
                                width: 36,
                                height: 36,
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark ? accentGreen : primaryColor,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: onPlayPause,
                                icon: Icon(
                                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  color: isDark ? accentGreen : primaryColor,
                                  size: 36,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                tooltip: isPlaying ? 'Pause' : 'Play',
                              ),
                        IconButton(
                          onPressed: onNext,
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: isDark ? Colors.white : primaryColor,
                            size: 26,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          tooltip: 'Next',
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'Close Player',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Interactive Progress Scrubber / Slider Bar
                Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: GoogleFonts.oxanium(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                          activeTrackColor: isDark ? accentGreen : primaryColor,
                          inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          thumbColor: isDark ? accentGreen : primaryColor,
                        ),
                        child: Slider(
                          value: currentPositionMs,
                          min: 0.0,
                          max: maxDurationMs,
                          onChanged: onSeek,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: GoogleFonts.oxanium(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
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
