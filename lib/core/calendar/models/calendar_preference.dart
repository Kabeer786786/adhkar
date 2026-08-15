import 'calendar_type.dart';

/// User preference model for calendar display mode and region selection.
class CalendarPreference {
  final CalendarType calendarType;
  final HijriRegion region;

  const CalendarPreference({
    required this.calendarType,
    required this.region,
  });

  static const defaultPreference = CalendarPreference(
    calendarType: CalendarType.regional,
    region: HijriRegion.india,
  );

  Map<String, dynamic> toJson() => {
        'calendarType': calendarType.name,
        'region': region.code,
      };

  factory CalendarPreference.fromJson(Map<String, dynamic> json) {
    final typeName = json['calendarType'] as String? ?? 'regional';
    final regionCode = json['region'] as String? ?? 'IN';

    return CalendarPreference(
      calendarType: typeName == 'global' ? CalendarType.global : CalendarType.regional,
      region: HijriRegionExtension.fromCountryCode(regionCode),
    );
  }

  CalendarPreference copyWith({
    CalendarType? calendarType,
    HijriRegion? region,
  }) {
    return CalendarPreference(
      calendarType: calendarType ?? this.calendarType,
      region: region ?? this.region,
    );
  }
}
