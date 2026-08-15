import 'hijri_date.dart';
export 'hijri_date.dart';

/// Utility class to convert Gregorian DateTime to Hijri Date string with regional offset support.
class HijriDateHelper {
  /// Calculates Hijri (Islamic) date from a Gregorian [DateTime] with optional [dayOffset].
  static HijriDate convertToHijri(DateTime gregorian, {int? dayOffset}) {
    return HijriDate.fromGregorian(gregorian, dayOffset: dayOffset);
  }

  /// Formats a Gregorian date into readable Hijri date string e.g. "1 Rabi' al-Awwal 1448 AH"
  static String formatHijri(DateTime gregorian, {int? dayOffset}) {
    final hijri = convertToHijri(gregorian, dayOffset: dayOffset);
    return '${hijri.day} ${hijri.monthNameEn}';
  }
}
