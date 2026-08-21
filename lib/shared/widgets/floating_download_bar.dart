import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/media_download_provider.dart';

/// A floating, non-blocking bottom progress bar widget that displays
/// real-time background audio download progress.
class FloatingDownloadBar extends ConsumerWidget {
  const FloatingDownloadBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(mediaDownloadProvider);

    if (!downloadState.isDownloading && !downloadState.isCompleted) {
      return const SizedBox.shrink();
    }

    final percentage = (downloadState.progress * 100).toInt();

    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: downloadState.isMinimized
                ? _buildMinimizedPill(context, ref, downloadState, percentage)
                : _buildExpandedCard(context, ref, downloadState, percentage),
          ),
        ), 
      ),
    );
  }

  /// Compact floating pill mode when minimized by user.
  Widget _buildMinimizedPill(
    BuildContext context,
    WidgetRef ref,
    MediaDownloadState state,
    int percentage,
  ) {
    return GestureDetector(
      onTap: () => ref.read(mediaDownloadProvider.notifier).toggleMinimize(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3512),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: state.isCompleted ? 1.0 : state.progress,
                strokeWidth: 3,
                color: const Color(0xFFD4AF37),
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              state.isCompleted ? 'Done' : '$percentage%',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.expand_less_rounded, color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }

  /// Detailed floating card showing download title, progress bar, and file counts.
  /// Features a close button positioned at the top-right corner edge inside the card.
  Widget _buildExpandedCard(
    BuildContext context,
    WidgetRef ref,
    MediaDownloadState state,
    int percentage,
  ) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 34, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3512),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    state.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.cloud_download_rounded,
                    color: state.isCompleted
                        ? Colors.lightGreenAccent
                        : const Color(0xFFD4AF37),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isCompleted ? 'Download Complete!' : state.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!state.isCompleted) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Downloading ${state.currentItemName}...',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${state.completedCount}/${state.totalCount}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.expand_more_rounded, color: Colors.white70, size: 20),
                    onPressed: () => ref.read(mediaDownloadProvider.notifier).toggleMinimize(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Minimize',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.isCompleted ? 1.0 : state.progress,
                  minHeight: 6,
                  color: const Color(0xFFD4AF37),
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
        ),

        // Close button at top-right corner inside the card
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: () => ref.read(mediaDownloadProvider.notifier).dismiss(),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white60,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
