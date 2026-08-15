import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calendar_preference.dart';
import '../models/calendar_type.dart';
import '../models/hijri_date.dart';
import '../services/hijri_calendar_service.dart';
import '../../../shared/providers/app_providers.dart';

/// Notifier managing persisted user calendar preferences.
class CalendarPreferenceNotifier extends StateNotifier<CalendarPreference> {
  static const String _prefBoxName = 'calendar_preference_box';
  static const String _prefKey = 'user_calendar_pref';

  CalendarPreferenceNotifier() : super(CalendarPreference.defaultPreference) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final box = Hive.isBoxOpen(_prefBoxName)
          ? Hive.box(_prefBoxName)
          : await Hive.openBox(_prefBoxName);

      final raw = box.get(_prefKey);
      if (raw != null && raw is Map) {
        state = CalendarPreference.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
  }

  Future<void> setCalendarPreference(CalendarPreference pref) async {
    state = pref;
    try {
      final box = Hive.isBoxOpen(_prefBoxName)
          ? Hive.box(_prefBoxName)
          : await Hive.openBox(_prefBoxName);
      await box.put(_prefKey, pref.toJson());
    } catch (_) {}
  }

  Future<void> setCalendarType(CalendarType type) async {
    await setCalendarPreference(state.copyWith(calendarType: type));
  }

  Future<void> setRegion(HijriRegion region) async {
    await setCalendarPreference(state.copyWith(region: region));
  }
}

final calendarPreferenceProvider =
    StateNotifierProvider<CalendarPreferenceNotifier, CalendarPreference>(
  (ref) => CalendarPreferenceNotifier(),
);

final hijriCalendarServiceProvider = Provider<HijriCalendarService>((ref) {
  return HijriCalendarService();
});

/// AsyncNotifier provider returning today's active Hijri date based on location and user calendar preference.
final activeTodayHijriProvider = FutureProvider<HijriDate>((ref) async {
  final pref = ref.watch(calendarPreferenceProvider);
  final location = ref.watch(currentLocationProvider).value;
  final service = ref.watch(hijriCalendarServiceProvider);

  // If user has not explicitly configured region, automatically derive region from location country
  final activeRegion = pref.region == HijriRegion.global && location?.country != null
      ? HijriRegionExtension.fromCountryCode(location!.country)
      : pref.region;

  return await service.getHijriDate(
    gregorianDate: DateTime.now(),
    calendarType: pref.calendarType,
    region: activeRegion,
  );
});
