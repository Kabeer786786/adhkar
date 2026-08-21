import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/media_download_provider.dart';
import '../../../../core/services/media_download_service.dart';
import '../../data/asma_ul_husna_data.dart';

class AsmaDownloadDialog extends ConsumerWidget {
  final List<MediaDownloadItem> items;

  const AsmaDownloadDialog({super.key, required this.items});

  static List<MediaDownloadItem> _buildDefaultItems() {
    return asmaUlHusnaList.map((item) {
      return MediaDownloadItem(
        id: 'asma_${item.number}',
        title: item.transliteration.isNotEmpty ? item.transliteration : 'Name #${item.number}',
        relativePath: item.localRelativePath,
        remoteUrl: item.remoteUrl,
      );
    }).toList();
  }

  /// Check if 99 names are downloaded or if prompt was already dismissed.
  /// If not, prompt user.
  static Future<void> showIfFirstTime(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyPrompted = prefs.getBool('asma_download_prompt_dismissed') ?? false;

    final defaultItems = _buildDefaultItems();
    final isAllDownloaded = await MediaDownloadService.instance.isBatchDownloaded(
      defaultItems.map((e) => e.relativePath).toList(),
    );

    if (!alreadyPrompted && !isAllDownloaded && context.mounted) {
      show(context, ref, items: defaultItems);
    }
  }

  /// Show download prompt dialog.
  static void show(BuildContext context, WidgetRef ref, {List<MediaDownloadItem>? items}) {
    final downloadItems = items ?? _buildDefaultItems();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AsmaDownloadDialog(items: downloadItems),
    );
  }

  static Future<void> _markPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('asma_download_prompt_dismissed', true);
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
            'Download all 99 Asma-ul-Husna audio recitations for offline listening. If you skip, audio will stream online.',
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
                  onPressed: () async {
                    await _markPromptDismissed();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Stream Online',
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
                  onPressed: () async {
                    await _markPromptDismissed();
                    if (context.mounted) Navigator.pop(context);
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
                    'Download All',
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
