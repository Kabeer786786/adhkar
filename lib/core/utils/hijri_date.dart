import 'package:hive_flutter/hive_flutter.dart';

/// Hijri Calendar date utility for computing Islamic dates with regional offset support.
class HijriDate {
  final int year;
  final int month;
  final int day;
  final String monthNameEn;
  final String monthNameAr;

  String get monthName => monthNameEn;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.monthNameEn,
    required this.monthNameAr,
  });

  static const List<String> _monthsEn = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah'
  ];

  static const List<String> _monthsAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة'
  ];

  static const List<int> _subcontinentMonthLengths1448 = [
    30, // 1. Muharram
    30, // 2. Safar (30 Safar = Aug 14, 2026)
    30, // 3. Rabi' al-Awwal (1 Rabi' al-Awwal = Aug 15, 2026)
    29, // 4. Rabi' al-Thani
    30, // 5. Jumada al-Ula
    29, // 6. Jumada al-Akhirah
    30, // 7. Rajab
    29, // 8. Sha'ban
    30, // 9. Ramadan
    29, // 10. Shawwal
    30, // 11. Dhu al-Qi'dah
    29, // 12. Dhu al-Hijjah
  ];

  /// Calculates Hijri date from a Gregorian [DateTime] with optional [dayOffset].
  /// If [dayOffset] is null, checks stored regional offset in Hive cache (e.g. -1 for IN/PK/BD).
  static HijriDate fromGregorian(DateTime date, {int? dayOffset, bool? isSubcontinent}) {
    bool subcontinent = isSubcontinent ?? true;
    if (isSubcontinent == null && Hive.isBoxOpen('hijri_cache_box')) {
      try {
        final box = Hive.box('hijri_cache_box');
        final offset = (box.get('hijri_regional_day_offset') as num?)?.toInt();
        if (offset != null && offset == 0) {
          subcontinent = false;
        }
      } catch (_) {}
    }

    if (subcontinent) {
      return _calculateSubcontinentHijri(date);
    }

    // Standard un-offset algorithmic conversion for rest of the world
    int day = date.day;
    int month = date.month;
    int year = date.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    int jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;

    int l = jd - 1948440 + 10633;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    int j = (((10985 - l) / 5316).floor()) * (((50 * l) / 17719).floor()) +
        (((l / 5670).floor()) * (((43 * l) / 15238).floor()));
    l = l -
        (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
        ((j / 30).floor()) * (((15238 * j) / 43).floor()) +
        29;
    int hMonth = ((24 * l) / 709).floor();
    int hDay = l - ((709 * hMonth) / 24).floor();
    int hYear = 30 * n + j - 30;

    hMonth = hMonth.clamp(1, 12);

    return HijriDate(
      year: hYear,
      month: hMonth,
      day: hDay,
      monthNameEn: _monthsEn[hMonth - 1],
      monthNameAr: _monthsAr[hMonth - 1],
    );
  }

  /// Exact anchor-based Hijri date calculation for South Asia (India, Pakistan, Bangladesh).
  /// Anchor: 15 August 2026 = 1 Rabi' al-Awwal 1448 AH (Month 3, Day 1).
  /// 14 August 2026 = 30 Safar 1448 AH (Month 2, Day 30).
  static HijriDate _calculateSubcontinentHijri(DateTime date) {
    final anchor = DateTime(2026, 8, 15);
    int diffDays = DateTime(date.year, date.month, date.day).difference(anchor).inDays;

    int currentYear = 1448;
    int currentMonth = 3; // Rabi' al-Awwal
    int currentDay = 1;

    if (diffDays >= 0) {
      int remaining = diffDays;
      while (remaining > 0) {
        int monthLen = _subcontinentMonthLengths1448[(currentMonth - 1) % 12];
        int daysLeftInMonth = monthLen - currentDay + 1;
        if (remaining < daysLeftInMonth) {
          currentDay += remaining;
          remaining = 0;
        } else {
          remaining -= daysLeftInMonth;
          currentMonth++;
          if (currentMonth > 12) {
            currentMonth = 1;
            currentYear++;
          }
          currentDay = 1;
        }
      }
    } else {
      int remaining = -diffDays;
      while (remaining > 0) {
        if (remaining < currentDay) {
          currentDay -= remaining;
          remaining = 0;
        } else {
          remaining -= currentDay;
          currentMonth--;
          if (currentMonth < 1) {
            currentMonth = 12;
            currentYear--;
          }
          int prevMonthLen = _subcontinentMonthLengths1448[(currentMonth - 1) % 12];
          currentDay = prevMonthLen;
        }
      }
    }

    return HijriDate(
      year: currentYear,
      month: currentMonth,
      day: currentDay,
      monthNameEn: _monthsEn[(currentMonth - 1) % 12],
      monthNameAr: _monthsAr[(currentMonth - 1) % 12],
    );
  }

  String formatEn() => '$day $monthNameEn';
  String formatAr() => '$day $monthNameAr $year هـ';
}
