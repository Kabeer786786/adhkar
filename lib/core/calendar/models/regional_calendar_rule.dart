import 'calendar_type.dart';

/// Configurable rule defining offset days and calendar type behavior for a specific region.
class RegionalCalendarRule {
  final HijriRegion region;
  final bool usesRegionalCalendar;
  final int defaultOffsetDays;

  const RegionalCalendarRule({
    required this.region,
    required this.usesRegionalCalendar,
    required this.defaultOffsetDays,
  });

  factory RegionalCalendarRule.fromJson(Map<String, dynamic> json) {
    final regionCode = json['region'] as String? ?? 'GLOBAL';
    return RegionalCalendarRule(
      region: HijriRegionExtension.fromCountryCode(regionCode),
      usesRegionalCalendar: json['usesRegionalCalendar'] as bool? ?? true,
      defaultOffsetDays: (json['offsetDays'] as num?)?.toInt() ?? -1,
    );
  }

  Map<String, dynamic> toJson() => {
        'region': region.code,
        'usesRegionalCalendar': usesRegionalCalendar,
        'offsetDays': defaultOffsetDays,
      };
}

/// Centralized configuration registry for regional calendar rules.
class HijriRegionConfig {
  static const Map<HijriRegion, RegionalCalendarRule> _defaultRules = {
    HijriRegion.global: RegionalCalendarRule(
      region: HijriRegion.global,
      usesRegionalCalendar: false,
      defaultOffsetDays: 0,
    ),
    HijriRegion.india: RegionalCalendarRule(
      region: HijriRegion.india,
      usesRegionalCalendar: true,
      defaultOffsetDays: -1,
    ),
    HijriRegion.pakistan: RegionalCalendarRule(
      region: HijriRegion.pakistan,
      usesRegionalCalendar: true,
      defaultOffsetDays: -1,
    ),
    HijriRegion.bangladesh: RegionalCalendarRule(
      region: HijriRegion.bangladesh,
      usesRegionalCalendar: true,
      defaultOffsetDays: -1,
    ),
  };

  static RegionalCalendarRule getRuleForRegion(HijriRegion region) {
    return _defaultRules[region] ?? _defaultRules[HijriRegion.global]!;
  }
}
