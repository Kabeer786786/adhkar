import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service responsible for managing Google Play In-App Updates.
///
/// Triggers Google Play's official update modal when a newer version is
/// available on the Google Play Store and auto-update is off or pending.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  bool _isChecking = false;

  /// Check for available updates on Google Play Store and prompt the user.
  ///
  /// [immediate]: If true (default), shows Google's full-screen modal requiring
  /// the user to update before continuing. If false, shows a flexible bottom sheet.
  Future<void> checkForUpdate({bool immediate = true}) async {
    // In-App Updates are only supported on Android and physical/store releases
    if (kIsWeb || !Platform.isAndroid) return;
    if (_isChecking) return;

    _isChecking = true;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint(
          '[AppUpdateService] New update available! Available version code: ${updateInfo.availableVersionCode}',
        );

        if (immediate && updateInfo.immediateUpdateAllowed) {
          debugPrint('[AppUpdateService] Launching Google Play immediate update modal...');
          final result = await InAppUpdate.performImmediateUpdate();
          debugPrint('[AppUpdateService] Immediate update result: $result');
        } else if (updateInfo.flexibleUpdateAllowed) {
          debugPrint('[AppUpdateService] Launching Google Play flexible update sheet...');
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        debugPrint('[AppUpdateService] App is up to date with Google Play Store.');
      }
    } catch (e) {
      // Common in debug mode or if app is not downloaded via Google Play Store
      debugPrint('[AppUpdateService] Update check skipped or not on Play Store: $e');
    } finally {
      _isChecking = false;
    }
  }
}
