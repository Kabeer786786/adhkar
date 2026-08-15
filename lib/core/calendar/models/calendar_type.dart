/// Defines whether to use standard global calculation or regional moon-sighting calculation.
enum CalendarType {
  global,
  regional,
}

/// Supported geographic regions for regional calendar rules.
enum HijriRegion {
  global,
  india,
  pakistan,
  bangladesh,
}

extension HijriRegionExtension on HijriRegion {
  String get displayName {
    switch (this) {
      case HijriRegion.india:
        return 'India';
      case HijriRegion.pakistan:
        return 'Pakistan';
      case HijriRegion.bangladesh:
        return 'Bangladesh';
      case HijriRegion.global:
        return 'Global / Standard';
    }
  }

  String get code {
    switch (this) {
      case HijriRegion.india:
        return 'IN';
      case HijriRegion.pakistan:
        return 'PK';
      case HijriRegion.bangladesh:
        return 'BD';
      case HijriRegion.global:
        return 'GLOBAL';
    }
  }

  static HijriRegion fromCountryCode(String? countryCode) {
    if (countryCode == null) return HijriRegion.global;
    final code = countryCode.toUpperCase().trim();
    if (code == 'IN' || code.contains('INDIA')) return HijriRegion.india;
    if (code == 'PK' || code.contains('PAKISTAN')) return HijriRegion.pakistan;
    if (code == 'BD' || code.contains('BANGLADESH')) return HijriRegion.bangladesh;
    return HijriRegion.global;
  }
}
