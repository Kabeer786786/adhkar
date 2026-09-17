import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_download_service.dart';

/// State model for background media download progress.
class MediaDownloadState {
  final MediaDownloadCategory category;
  final bool isDownloading;
  final bool isCompleted;
  final bool isMinimized;
  final String title;
  final int completedCount;
  final int totalCount;
  final double progress;
  final String currentItemName;
  final String? errorMessage;

  const MediaDownloadState({
    this.category = MediaDownloadCategory.quran,
    this.isDownloading = false,
    this.isCompleted = false,
    this.isMinimized = false,
    this.title = '',
    this.completedCount = 0,
    this.totalCount = 0,
    this.progress = 0.0,
    this.currentItemName = '',
    this.errorMessage,
  });

  MediaDownloadState copyWith({
    MediaDownloadCategory? category,
    bool? isDownloading,
    bool? isCompleted,
    bool? isMinimized,
    String? title,
    int? completedCount,
    int? totalCount,
    double? progress,
    String? currentItemName,
    String? errorMessage,
  }) {
    return MediaDownloadState(
      category: category ?? this.category,
      isDownloading: isDownloading ?? this.isDownloading,
      isCompleted: isCompleted ?? this.isCompleted,
      isMinimized: isMinimized ?? this.isMinimized,
      title: title ?? this.title,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      progress: progress ?? this.progress,
      currentItemName: currentItemName ?? this.currentItemName,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier class managing the background media downloader state.
class MediaDownloadNotifier extends StateNotifier<MediaDownloadState> {
  final MediaDownloadCategory category;

  MediaDownloadNotifier({this.category = MediaDownloadCategory.quran})
      : super(MediaDownloadState(category: category));

  /// Start a background download task.
  Future<void> startBatchDownload({
    required String taskTitle,
    required List<MediaDownloadItem> items,
  }) async {
    if (state.isDownloading) return; // Prevent duplicate tasks

    state = MediaDownloadState(
      category: category,
      isDownloading: true,
      isCompleted: false,
      isMinimized: false,
      title: taskTitle,
      totalCount: items.length,
      completedCount: 0,
      progress: 0.0,
      currentItemName: items.isNotEmpty ? items.first.title : '',
    );

    await MediaDownloadService.instance.downloadBatch(
      category: category,
      items: items,
      onBatchProgress: (completed, total, progress, currentItem) {
        state = state.copyWith(
          completedCount: completed,
          totalCount: total,
          progress: progress,
          currentItemName: currentItem,
          isCompleted: completed >= total,
          isDownloading: completed < total,
        );
      },
      onError: (error) {
        state = state.copyWith(errorMessage: error);
      },
    );
  }

  /// Toggle minimizing the floating progress bar.
  void toggleMinimize() {
    state = state.copyWith(isMinimized: !state.isMinimized);
  }

  /// Dismiss or cancel the current download task.
  void dismiss() {
    MediaDownloadService.instance.cancelDownload(category);
    state = MediaDownloadState(category: category);
  }
}

/// Dedicated provider for Quran audio downloads
final quranDownloadProvider =
    StateNotifierProvider<MediaDownloadNotifier, MediaDownloadState>((ref) {
  return MediaDownloadNotifier(category: MediaDownloadCategory.quran);
});

/// Dedicated provider for Asma-ul-Husna audio downloads
final asmaDownloadProvider =
    StateNotifierProvider<MediaDownloadNotifier, MediaDownloadState>((ref) {
  return MediaDownloadNotifier(category: MediaDownloadCategory.asmaUlHusna);
});

/// Riverpod Provider exposing the media download notifier state (defaults to Quran for backwards compatibility).
final mediaDownloadProvider = quranDownloadProvider;
