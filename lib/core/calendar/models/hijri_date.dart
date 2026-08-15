/// Complete domain immutable model representing a Hijri date.
class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthNameEn;
  final String monthNameAr;
  final String weekday;
  final String formatted;
  final String region;
  final String source;
  final bool isAladhan;

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthNameEn,
    required this.monthNameAr,
    required this.weekday,
    required this.formatted,
    required this.region,
    required this.source,
    required this.isAladhan,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'month': month,
        'year': year,
        'monthNameEn': monthNameEn,
        'monthNameAr': monthNameAr,
        'weekday': weekday,
        'formatted': formatted,
        'region': region,
        'source': source,
        'isAladhan': isAladhan,
      };

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      day: (json['day'] as num?)?.toInt() ?? 1,
      month: (json['month'] as num?)?.toInt() ?? 1,
      year: (json['year'] as num?)?.toInt() ?? 1448,
      monthNameEn: json['monthNameEn'] as String? ?? 'Muharram',
      monthNameAr: json['monthNameAr'] as String? ?? 'مُحَرَّم',
      weekday: json['weekday'] as String? ?? '',
      formatted: json['formatted'] as String? ?? '',
      region: json['region'] as String? ?? 'Global',
      source: json['source'] as String? ?? 'api',
      isAladhan: json['isAladhan'] as bool? ?? false,
    );
  }
}
