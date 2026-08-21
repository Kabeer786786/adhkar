import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/media_download_provider.dart';
import '../../../../core/services/media_download_service.dart';

class SurahDownloadDialog extends ConsumerWidget {
  final String title;
  final int totalVerses;
  final List<MediaDownloadItem> items;

  const SurahDownloadDialog({
    super.key,
    required this.title,
    required this.totalVerses,
    required this.items,
  });

  /// Check if a Surah/Juz is downloaded, if not show the download prompt.
  static Future<void> checkAndPrompt({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required List<MediaDownloadItem> items,
  }) async {
    final isDownloaded = await MediaDownloadService.instance.isBatchDownloaded(
      items.map((e) => e.relativePath).toList(),
    );

    if (!isDownloaded && context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => SurahDownloadDialog(
          title: title,
          totalVerses: items.length,
          items: items,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3512).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Color(0xFF1A3512),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Download Audio for $title?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3512),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download verse recitations for $title ($totalVerses verses) for offline gapless playback. You can continue reading while it downloads in the background.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Read Only',
                    style: GoogleFonts.outfit(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(mediaDownloadProvider.notifier).startBatchDownload(
                          taskTitle: 'Downloading $title Audios',
                          items: items,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3512),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Download Audio',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
