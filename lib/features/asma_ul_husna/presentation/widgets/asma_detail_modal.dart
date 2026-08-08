import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/asma_ul_husna_model.dart';

class AsmaDetailModal extends StatefulWidget {
  final AsmaUlHusna item;
  final VoidCallback? onPlayContinuous;

  const AsmaDetailModal({
    super.key,
    required this.item,
    this.onPlayContinuous,
  });

  static Future<void> show(
    BuildContext context, {
    required AsmaUlHusna item,
    VoidCallback? onPlayContinuous,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AsmaDetailModal(
        item: item,
        onPlayContinuous: onPlayContinuous,
      ),
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
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
          _isLoading = state.processingState == ProcessingState.buffering ||
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
        await _audioPlayer.setUrl(widget.item.audioUrl);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing single audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Header row with badge & close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A531D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Name : ${widget.item.number}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A531D),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Decorative Mosque / Star background container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE8F4E5),
                  const Color(0xFFF3F7F2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
            ),
            child: Column(
              children: [
                // Big Arabic Name
                Text(
                  widget.item.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A3512),
                    height: 1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Play Icon Button for Pronunciation
                GestureDetector(
                  onTap: _playSingleAudio,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A531D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2A531D).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.volume_up_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPlaying ? 'Playing Pronunciation' : 'Tap to Listen',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B6B42),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Transliteration & Meaning Showcase Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      FlutterIslamicIcons.solidAllah,
                      size: 18,
                      color: Color(0xFFD97724),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TRANSLITERATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF8C6D53),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.transliteration,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A531D),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.8),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ENGLISH MEANING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF8C6D53),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.meaning,
                  style: GoogleFonts.lexend(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A3512),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Option to play playlist from here
          if (widget.onPlayContinuous != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPlayContinuous?.call();
                },
                icon: const Icon(Icons.playlist_play_rounded, size: 24),
                label: const Text(
                  'Play All 99 Names from Here',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A531D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
