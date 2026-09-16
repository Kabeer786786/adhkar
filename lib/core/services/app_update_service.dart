import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service responsible for managing Google Play In-App Updates.
///
/// Returns update availability info so the UI can show a custom bottom sheet
/// instead of Google Play's native full-screen modal.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  bool _isChecking = false;

  /// Checks Google Play for available updates.
  /// Returns the [AppUpdateInfo] if an update is available, or null otherwise.
  Future<AppUpdateInfo?> checkForUpdate() async {
    // In-App Updates are only supported on Android and physical/store releases
    if (kIsWeb || !Platform.isAndroid) return null;
    if (_isChecking) return null;

    _isChecking = true;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint(
          '[AppUpdateService] New update available! Available version code: ${updateInfo.availableVersionCode}',
        );
        return updateInfo;
      } else {
        debugPrint('[AppUpdateService] App is up to date with Google Play Store.');
        return null;
      }
    } catch (e) {
      // Common in debug mode or if app is not downloaded via Google Play Store
      debugPrint('[AppUpdateService] Update check skipped or not on Play Store: $e');
      return null;
    } finally {
      _isChecking = false;
    }
  }

  /// Starts Google Play's flexible update flow.
  Future<void> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[AppUpdateService] Flexible update failed: $e');
    }
  }

  /// Starts Google Play's immediate update flow (full-screen modal).
  Future<void> startImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('[AppUpdateService] Immediate update failed: $e');
    }
  }
}
