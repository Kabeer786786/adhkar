import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for managing background downloading and local caching
/// of audio files from GitHub Releases or custom CDN sources.
class MediaDownloadService {
  static final MediaDownloadService instance = MediaDownloadService._internal();
  MediaDownloadService._internal();

  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  /// Default GitHub Releases base URL for audio assets.
  /// Example: https://github.com/Kabeer786786/adhkar/releases/download/v1.0.0/
  String baseUrl = 'https://github.com/Kabeer786786/adhkar/releases/download/v1.0.0';

  /// Get the root directory for storing downloaded audio assets.
  Future<Directory> get _audioDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${docsDir.path}/audios');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// Get the local File object for a given subpath (e.g. 'asma_ul_husna/1.mp3' or 'quran/1.mp3').
  Future<File> getLocalFile(String relativePath) async {
    final root = await _audioDirectory;
    return File('${root.path}/$relativePath');
  }

  /// Check if a specific file exists locally and is valid.
  Future<bool> isFileDownloaded(String relativePath) async {
    final file = await getLocalFile(relativePath);
    return await file.exists() && (await file.length()) > 0;
  }

  /// Check if all files in a relative path list are downloaded.
  Future<bool> isBatchDownloaded(List<String> relativePaths) async {
    for (final path in relativePaths) {
      final downloaded = await isFileDownloaded(path);
      if (!downloaded) return false;
    }
    return true;
  }

  /// Get count of already downloaded files in a batch.
  Future<int> getDownloadedCount(List<String> relativePaths) async {
    int count = 0;
    for (final path in relativePaths) {
      if (await isFileDownloaded(path)) {
        count++;
      }
    }
    return count;
  }

  /// Helper to check if audio is local. If local -> calls [onPlayLocal].
  /// If NOT local -> prompts the user to download audio first via [onPromptDownload].
  Future<void> ensureLocalOrPrompt({
    required List<String> relativePaths,
    required VoidCallback onPlayLocal,
    required VoidCallback onPromptDownload,
  }) async {
    final downloaded = await isBatchDownloaded(relativePaths);
    if (downloaded) {
      onPlayLocal();
    } else {
      onPromptDownload();
    }
  }

  /// Download a single file if not already present.
  /// Note: remoteUrl is ONLY used here for fetching, never for live streaming.
  Future<File> downloadFile({
    required String relativePath,
    required String remoteUrl,
    CancelToken? cancelToken,
    Function(int received, int total)? onProgress,
  }) async {
    final localFile = await getLocalFile(relativePath);
    if (await localFile.exists() && (await localFile.length()) > 0) {
      return localFile;
    }

    await localFile.parent.create(recursive: true);
    final tempFile = File('${localFile.path}.tmp');

    try {
      await _dio.download(
        remoteUrl,
        tempFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );
      if (await tempFile.exists()) {
        await tempFile.rename(localFile.path);
      }
      return localFile;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// Download a batch of audio files sequentially in the background.
  /// Notifies [onBatchProgress] after each file download.
  Future<void> downloadBatch({
    required List<MediaDownloadItem> items,
    required Function(int completedCount, int totalCount, double progress, String currentItem) onBatchProgress,
    Function(String error)? onError,
  }) async {
    _cancelToken = CancelToken();
    final total = items.length;
    int completed = 0;

    for (final item in items) {
      if (_cancelToken?.isCancelled ?? false) break;

      final isAlreadyDownloaded = await isFileDownloaded(item.relativePath);
      if (isAlreadyDownloaded) {
        completed++;
        onBatchProgress(completed, total, completed / total, item.title);
        continue;
      }

      try {
        final url = item.remoteUrl.startsWith('http')
            ? item.remoteUrl
            : '$baseUrl/${item.remoteUrl}';

        await downloadFile(
          relativePath: item.relativePath,
          remoteUrl: url,
          cancelToken: _cancelToken,
        );

        completed++;
        onBatchProgress(completed, total, completed / total, item.title);
      } catch (e) {
        if (CancelToken.isCancel(e as DioException)) {
          break;
        }
        onError?.call('Failed downloading ${item.title}: $e');
        // Continue downloading next files in batch
      }
    }
  }

  /// Cancel any ongoing background batch download.
  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
  }
}

/// Represents an item to download in a batch.
class MediaDownloadItem {
  final String id;
  final String title;
  final String relativePath;
  final String remoteUrl;

  const MediaDownloadItem({
    required this.id,
    required this.title,
    required this.relativePath,
    required this.remoteUrl,
  });
}
