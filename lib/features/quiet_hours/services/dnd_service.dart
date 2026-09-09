import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Represents the current Do Not Disturb state reported by native Android.
class DndStateModel {
  final int filter; // 1=ALL, 2=PRIORITY, 3=NONE, 4=ALARMS
  final bool isDndActive;
  final bool adhkarOwnsDnd;

  const DndStateModel({
    required this.filter,
    required this.isDndActive,
    required this.adhkarOwnsDnd,
  });

  factory DndStateModel.fromMap(Map<dynamic, dynamic> map) {
    return DndStateModel(
      filter: (map['filter'] as num?)?.toInt() ?? 1,
      isDndActive: map['isDndActive'] as bool? ?? false,
      adhkarOwnsDnd: map['adhkarOwnsDnd'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'DndStateModel(filter: $filter, isDndActive: $isDndActive, adhkarOwnsDnd: $adhkarOwnsDnd)';
}

/// Represents the persisted DND schedule reconstructed on native Android.
class DndScheduleModel {
  final bool enabled;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool repeatDaily;
  final List<int> weekdays;
  final DateTime? nextEnableTime;
  final DateTime? nextDisableTime;
  final String timeZone;
  final String lastKnownDndState;
  final bool adhkarOwnsDnd;

  const DndScheduleModel({
    required this.enabled,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.repeatDaily,
    required this.weekdays,
    this.nextEnableTime,
    this.nextDisableTime,
    required this.timeZone,
    required this.lastKnownDndState,
    required this.adhkarOwnsDnd,
  });

  factory DndScheduleModel.fromMap(Map<dynamic, dynamic> map) {
    final nextEnableMs = (map['nextEnableTimestamp'] as num?)?.toInt() ?? 0;
    final nextDisableMs = (map['nextDisableTimestamp'] as num?)?.toInt() ?? 0;

    return DndScheduleModel(
      enabled: map['enabled'] as bool? ?? false,
      startHour: (map['startHour'] as num?)?.toInt() ?? 0,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 0,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      repeatDaily: map['repeatDaily'] as bool? ?? true,
      weekdays: (map['weekdays'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          [1, 2, 3, 4, 5, 6, 7],
      nextEnableTime: nextEnableMs > 0 ? DateTime.fromMillisecondsSinceEpoch(nextEnableMs) : null,
      nextDisableTime: nextDisableMs > 0 ? DateTime.fromMillisecondsSinceEpoch(nextDisableMs) : null,
      timeZone: map['timeZone'] as String? ?? 'UTC',
      lastKnownDndState: map['lastKnownDndState'] as String? ?? 'UNKNOWN',
      adhkarOwnsDnd: map['adhkarOwnsDnd'] as bool? ?? false,
    );
  }
}

/// Clean Flutter MethodChannel service interfacing with Android's native DndScheduler.
class DndService {
  static final DndService _instance = DndService._internal();
  factory DndService() => _instance;
  DndService._internal();

  static const MethodChannel _channel = MethodChannel('com.sprnt.adhkar/dnd_scheduler');

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Checks if Notification Policy Access (DND control) is granted on Android.
  Future<bool> isDndAccessGranted() async {
    if (!isSupported) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('isDndAccessGranted');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking DND access: ${e.message}');
      return false;
    }
  }

  /// Opens the system Notification Policy Access settings screen.
  Future<bool> openDndAccessSettings() async {
    if (!isSupported) return false;
    try {
      final opened = await _channel.invokeMethod<bool>('openDndAccessSettings');
      return opened ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error opening DND settings: ${e.message}');
      return false;
    }
  }

  /// Schedules DND using native Android AlarmManager.
  /// Execution is completely independent of the Flutter lifecycle.
  Future<bool> scheduleDnd({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    bool repeatDaily = true,
    List<int>? weekdays,
    String scheduleId = 'dnd_primary',
    String title = 'Quiet Hours',
  }) async {
    if (!isSupported) return false;
    try {
      final success = await _channel.invokeMethod<bool>('scheduleDnd', {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'repeatDaily': repeatDaily,
        'weekdays': weekdays ?? const [1, 2, 3, 4, 5, 6, 7],
        'scheduleId': scheduleId,
        'title': title,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error scheduling DND: ${e.message}');
      return false;
    }
  }

  /// Cancels scheduled DND alarms and optionally restores prior state.
  Future<bool> cancelDnd({
    String scheduleId = 'dnd_primary',
    bool restoreDnd = true,
  }) async {
    if (!isSupported) return false;
    try {
      final success = await _channel.invokeMethod<bool>('cancelDnd', {
        'scheduleId': scheduleId,
        'restoreDnd': restoreDnd,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error canceling DND: ${e.message}');
      return false;
    }
  }

  /// Retrieves the native schedule reconstructed from Android SharedPreferences.
  Future<DndScheduleModel?> getDndSchedule() async {
    if (!isSupported) return null;
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDndSchedule');
      if (map == null) return null;
      return DndScheduleModel.fromMap(map);
    } on PlatformException catch (e) {
      debugPrint('Error fetching DND schedule: ${e.message}');
      return null;
    }
  }

  /// Retrieves current interruption filter and DND ownership status.
  Future<DndStateModel> getCurrentDndState() async {
    if (!isSupported) {
      return const DndStateModel(filter: 1, isDndActive: false, adhkarOwnsDnd: false);
    }
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentDndState');
      if (map == null) {
        return const DndStateModel(filter: 1, isDndActive: false, adhkarOwnsDnd: false);
      }
      return DndStateModel.fromMap(map);
    } on PlatformException catch (e) {
      debugPrint('Error fetching current DND state: ${e.message}');
      return const DndStateModel(filter: 1, isDndActive: false, adhkarOwnsDnd: false);
    }
  }

  /// Checks if exact alarms are permitted on Android 12+ (API 31+).
  Future<bool> canScheduleExactAlarms() async {
    if (!isSupported) return true;
    try {
      final can = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return can ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system settings screen to grant SCHEDULE_EXACT_ALARM.
  Future<void> openExactAlarmSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
    }
  }

  /// Checks whether power-saving battery optimizations are ignored.
  Future<bool> isBatteryOptimizationIgnored() async {
    if (!isSupported) return true;
    try {
      final ignored = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return ignored ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Requests ignoring battery optimizations to avoid Doze delays on custom OEM skins.
  Future<void> requestIgnoreBatteryOptimization() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (e) {
      debugPrint('Error requesting ignore battery optimization: $e');
    }
  }
}
