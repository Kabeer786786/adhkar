/// Utility class to convert Gregorian DateTime to Hijri Date string.
class HijriDateHelper {
  static const List<String> _months = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  /// Calculates Hijri (Islamic) date from a Gregorian [DateTime].
  static HijriDate convertToHijri(DateTime gregorian) {
    final day = gregorian.day;
    final month = gregorian.month;
    final year = gregorian.year;

    // Convert to Julian Day
    int m = month;
    int y = year;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524;

    // Convert Julian Day to Hijri date
    int l = jd - 1948440 + 10633;
    final n = (l / 10631).floor();
    l = l - 10631 * n + 354;
    final j = ((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor() +
        (l / 5670).floor() * ((43 * l) / 15238).floor();
    l = l -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final hMonth = ((24 * l) / 709).floor();
    final hDay = l - ((709 * hMonth) / 24).floor();
    final hYear = 30 * n + j - 30;

    return HijriDate(
      day: hDay.clamp(1, 30),
      month: hMonth.clamp(1, 12),
      year: hYear,
      monthName: _months[(hMonth - 1).clamp(0, 11)],
    );
  }

  /// Formats a Gregorian date into readable Hijri date string e.g. "20 Rabi' al-Awwal 1446 AH"
  static String formatHijri(DateTime gregorian) {
    final hijri = convertToHijri(gregorian);
    return '${hijri.day} ${hijri.monthName}';
  }
}

class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName;

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
  });
}
