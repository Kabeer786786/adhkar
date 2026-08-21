import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/media_download_provider.dart';
import '../../../../core/services/media_download_service.dart';

class AsmaDownloadDialog extends ConsumerWidget {
  final List<MediaDownloadItem> items;

  const AsmaDownloadDialog({super.key, required this.items});

  /// Check if 99 names are downloaded on first screen load. If not, show dialog.
  static Future<void> showIfFirstTime(BuildContext context, WidgetRef ref) async {
    final defaultItems = List.generate(99, (index) {
      final id = index + 1;
      return MediaDownloadItem(
        id: 'asma_$id',
        title: 'Name #$id',
        relativePath: 'asma_ul_husna/$id.mp3',
        remoteUrl: 'https://github.com/Kabeer786786/adhkar/releases/download/v1.0.0/asma-ul-husna-$id.mp3',
      );
    });

    final isAllDownloaded = await MediaDownloadService.instance.isBatchDownloaded(
      defaultItems.map((e) => e.relativePath).toList(),
    );

    if (!isAllDownloaded && context.mounted) {
      show(context, ref, items: defaultItems);
    }
  }

  /// Show download prompt when user attempts to play audio without having downloaded it.
  static void show(BuildContext context, WidgetRef ref, {List<MediaDownloadItem>? items}) {
    final downloadItems = items ??
        List.generate(99, (index) {
          final id = index + 1;
          return MediaDownloadItem(
            id: 'asma_$id',
            title: 'Name #$id',
            relativePath: 'asma_ul_husna/$id.mp3',
            remoteUrl: 'https://github.com/Kabeer786786/adhkar/releases/download/v1.0.0/asma-ul-husna-$id.mp3',
          );
        });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AsmaDownloadDialog(items: downloadItems),
    );
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
              Icons.cloud_download_rounded,
              color: Color(0xFF1A3512),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Download 99 Names Audio?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A3512),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Audio playback is local-first. Download all 99 Asma-ul-Husna audio recitations for seamless offline listening (~15 MB). Downloads run in the background while you continue browsing.',
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
                    'Cancel',
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
                          taskTitle: 'Downloading 99 Asma-ul-Husna Audios',
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
                    'Download in Background',
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
