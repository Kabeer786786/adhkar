/// Hijri Calendar date utility for computing Islamic dates.
class HijriDate {
  final int year;
  final int month;
  final int day;
  final String monthNameEn;
  final String monthNameAr;

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

  /// Calculates Hijri date from a Gregorian [DateTime]
  static HijriDate fromGregorian(DateTime date) {
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

  String formatEn() => '$day $monthNameEn';
  String formatAr() => '$day $monthNameAr $year هـ';
}
