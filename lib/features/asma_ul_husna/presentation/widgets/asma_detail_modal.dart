import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/asma_ul_husna_model.dart';

class AsmaDetailModal extends StatefulWidget {
  final AsmaUlHusna item;
  final VoidCallback? onPlayContinuous;

  const AsmaDetailModal({super.key, required this.item, this.onPlayContinuous});

  static Future<void> show(
    BuildContext context, {
    required AsmaUlHusna item,
    VoidCallback? onPlayContinuous,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AsmaDetailModal(item: item, onPlayContinuous: onPlayContinuous),
    );
  }

  @override
  State<AsmaDetailModal> createState() => _AsmaDetailModalState();
}

class _AsmaDetailModalState extends State<AsmaDetailModal> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying =
              state.playing &&
              state.processingState != ProcessingState.completed;
          _isLoading =
              state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSingleAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        final mediaItem = MediaItem(
          id: 'asma_modal_${widget.item.number}',
          album: 'Asma ul Husna (${widget.item.number}/99)',
          title:
              '${widget.item.number}. ${widget.item.name} - ${widget.item.transliteration}',
          artist: '${widget.item.shortMeaning} (${widget.item.number}/99)',
        );
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(widget.item.audioUrl), tag: mediaItem),
        );
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing single audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxModalHeight = MediaQuery.of(context).size.height * 0.8;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header row with badge & close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF143820)
                        : const Color(0xFF2A531D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'NAME ${widget.item.number} OF 99',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF2A531D),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.grey,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF27272A)
                        : Colors.grey.shade100,
                    padding: const EdgeInsets.all(8),
                  ),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable main content styled like DuaDetailScreen
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Decorative Showcase Card with Big Arabic Name + Volume Icon at Bottom Left Corner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF143820), Color(0xFF18181B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFE8F4E5), Color(0xFFF4FAF3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFC8E6C9),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Centered Arabic Name
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SelectableText(
                              widget.item.name,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: AppTypography.arabicHeader(
                                fontSize: 42,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A3512),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),

                        // Volume Icon at Bottom Left Corner (No "Tap to listen" text)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: GestureDetector(
                            onTap: _playSingleAudio,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF18A74C)
                                    : const Color(0xFF2A531D),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isDark
                                                ? const Color(0xFF18A74C)
                                                : const Color(0xFF2A531D))
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: isDark
                                            ? const Color(0xFF0F0F12)
                                            : Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.volume_up_rounded,
                                      size: 20,
                                      color: isDark
                                          ? const Color(0xFF0F0F12)
                                          : Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Transliteration Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F0F12)
                          : const Color(0xFFF8FAF7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              FlutterIslamicIcons.solidAllah,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFD97724),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TRANSLITERATION',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF8C6D53),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.item.transliteration,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2A531D),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            height: 1,
                            thickness: 0.8,
                            color: isDark ? const Color(0xFF27272A) : null,
                          ),
                        ),

                        // Short Meaning Section
                        Row(
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 15,
                              color: isDark
                                  ? const Color(0xFF18A74C)
                                  : const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SHORT MEANING',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF8C6D53),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.item.shortMeaning,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF1A3512),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Detailed Meaning & Description Showcase (Dua Detail Screen style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1A14)
                          : const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3E3620)
                            : const Color(0xFFFEF08A),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFD97724),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DETAILED MEANING & DESCRIPTION',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isDark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFD97724),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          widget.item.longMeaning,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFF4A3728),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Play continuous button
                  if (widget.onPlayContinuous != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onPlayContinuous?.call();
                        },
                        icon: const Icon(Icons.playlist_play_rounded, size: 22),
                        label: const Text(
                          'Play All 99 Names from Here',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF18A74C)
                              : const Color(0xFF2A531D),
                          foregroundColor: isDark
                              ? const Color(0xFF0F0F12)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
