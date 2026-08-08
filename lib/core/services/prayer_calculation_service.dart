import 'dart:math' as math;

class PrayerTimeResult {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime qiyam;

  const PrayerTimeResult({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.qiyam,
  });

  Map<String, DateTime> toMap() {
    return {
      'Fajr': fajr,
      'Sunrise': sunrise,
      'Dhuhr': dhuhr,
      'Asr': asr,
      'Maghrib': maghrib,
      'Isha': isha,
      'Qiyam': qiyam,
    };
  }
}

class CalculationParameters {
  final double fajrAngle;
  final double ishaAngle;
  final int ishaMinutes; // Used if fixed minutes after Maghrib (e.g. Makkah method)

  const CalculationParameters({
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaMinutes = 0,
  });
}

class PrayerCalculationService {
  static const Map<String, CalculationParameters> methods = {
    'MWL': CalculationParameters(fajrAngle: 18.0, ishaAngle: 17.0),
    'ISNA': CalculationParameters(fajrAngle: 15.0, ishaAngle: 15.0),
    'EGYPT': CalculationParameters(fajrAngle: 19.5, ishaAngle: 17.5),
    'MAKKAH': CalculationParameters(fajrAngle: 18.5, ishaAngle: 0, ishaMinutes: 90),
    'KARACHI': CalculationParameters(fajrAngle: 18.0, ishaAngle: 18.0),
    'TEHRAN': CalculationParameters(fajrAngle: 17.7, ishaAngle: 14.0),
    'GULF': CalculationParameters(fajrAngle: 19.5, ishaAngle: 0, ishaMinutes: 90),
  };

  /// Calculates prayer times for a specified date, lat, lng, calculation method and juristic Asr rule.
  static PrayerTimeResult calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    String methodName = 'KARACHI',
    String juristicAsr = 'Hanafi',
  }) {
    final params = methods[methodName] ?? methods['KARACHI']!;
    final shadowFactor = (juristicAsr == 'Hanafi') ? 2.0 : 1.0;

    final julianDate = _getJulianDate(date.year, date.month, date.day);
    final timezoneOffset = date.timeZoneOffset.inMinutes / 60.0;

    final sunPos = _sunPosition(julianDate);
    final decl = sunPos.declination;
    final eqt = sunPos.equationOfTime;

    // Dhuhr solar noon
    final dhuhrHour = 12.0 + timezoneOffset - (longitude / 15.0) - (eqt / 60.0);

    // Sunrise & Sunset (Maghrib)
    final sunriseHour = _hourAngleToTime(dhuhrHour, _sunAngleTime(0.8333, latitude, decl, isSunrise: true));
    final sunsetHour = _hourAngleToTime(dhuhrHour, _sunAngleTime(0.8333, latitude, decl, isSunrise: false));

    // Fajr
    final fajrHour = _hourAngleToTime(dhuhrHour, _sunAngleTime(params.fajrAngle, latitude, decl, isSunrise: true));

    // Asr
    final asrAngle = _asrAngle(shadowFactor, latitude, decl);
    final asrHour = _hourAngleToTime(dhuhrHour, _sunAngleTime(asrAngle, latitude, decl, isSunrise: false, isAsrAngle: true));

    // Isha
    double ishaHour;
    if (params.ishaMinutes > 0) {
      ishaHour = sunsetHour + (params.ishaMinutes / 60.0);
    } else {
      ishaHour = _hourAngleToTime(dhuhrHour, _sunAngleTime(params.ishaAngle, latitude, decl, isSunrise: false));
    }

    final fajr = _doubleToDateTime(date, fajrHour);
    final sunrise = _doubleToDateTime(date, sunriseHour);
    final dhuhr = _doubleToDateTime(date, dhuhrHour);
    final asr = _doubleToDateTime(date, asrHour);
    final maghrib = _doubleToDateTime(date, sunsetHour);
    final isha = _doubleToDateTime(date, ishaHour);

    // Qiyam (last third of the night between Maghrib and Fajr of next day)
    final nextFajr = fajr.add(const Duration(days: 1));
    final nightDuration = nextFajr.difference(maghrib);
    final qiyam = maghrib.add(Duration(seconds: (nightDuration.inSeconds * (2 / 3)).round()));

    return PrayerTimeResult(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      qiyam: qiyam,
    );
  }

  static double _getJulianDate(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() + (30.6001 * (month + 1)).floor() + day + b - 1524.5;
  }

  static _SunPosition _sunPosition(double julianDate) {
    final d = julianDate - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * math.sin(_degToRad(g)) + 0.020 * math.sin(_degToRad(2 * g)));

    final e = 23.439 - 0.00000036 * d;
    final ra = _radToDeg(math.atan2(math.cos(_degToRad(e)) * math.sin(_degToRad(l)), math.cos(_degToRad(l)))) / 15.0;
    final eqt = q / 15.0 - _fixHour(ra);
    final decl = _radToDeg(math.asin(math.sin(_degToRad(e)) * math.sin(_degToRad(l))));

    return _SunPosition(declination: decl, equationOfTime: eqt * 60.0);
  }

  static double _sunAngleTime(double angle, double lat, double decl, {required bool isSunrise, bool isAsrAngle = false}) {
    final latRad = _degToRad(lat);
    final declRad = _degToRad(decl);
    final angleRad = _degToRad(angle);

    double cosH;
    if (isAsrAngle) {
      cosH = (math.sin(angleRad) - math.sin(latRad) * math.sin(declRad)) / (math.cos(latRad) * math.cos(declRad));
    } else {
      cosH = (-math.sin(angleRad) - math.sin(latRad) * math.sin(declRad)) / (math.cos(latRad) * math.cos(declRad));
    }

    cosH = cosH.clamp(-1.0, 1.0);
    final h = _radToDeg(math.acos(cosH)) / 15.0;
    return isSunrise ? -h : h;
  }

  static double _asrAngle(double shadowFactor, double lat, double decl) {
    final phiMinusD = (lat - decl).abs();
    final term = shadowFactor + math.tan(_degToRad(phiMinusD));
    return _radToDeg(math.atan(1.0 / term));
  }

  static double _hourAngleToTime(double dhuhrHour, double hourAngle) {
    return dhuhrHour + hourAngle;
  }

  static DateTime _doubleToDateTime(DateTime date, double hours) {
    hours = _fixHour(hours);
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    final s = (((hours - h) * 60 - m) * 60).round();
    return DateTime(date.year, date.month, date.day, h, m.clamp(0, 59), s.clamp(0, 59));
  }

  static double _degToRad(double degree) => degree * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
  static double _fixAngle(double angle) => angle - 360.0 * (angle / 360.0).floor();
  static double _fixHour(double hour) => hour - 24.0 * (hour / 24.0).floor();
}

class _SunPosition {
  final double declination;
  final double equationOfTime;

  _SunPosition({required this.declination, required this.equationOfTime});
}
