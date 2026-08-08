/// Generic API response structure from AlAdhan API.
class AlAdhanApiResponse<T> {
  final int code;
  final String status;
  final T data;

  const AlAdhanApiResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  bool get isSuccess => code == 200 && status.toUpperCase() == 'OK';

  factory AlAdhanApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return AlAdhanApiResponse<T>(
      code: json['code'] is int ? json['code'] as int : int.tryParse(json['code'].toString()) ?? 200,
      status: json['status'] as String? ?? 'OK', 
      data: fromJsonT(json['data']),
    );
  }
}

/// Prayer timings object containing timestamps or HH:mm string values.
class AlAdhanTimings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String imsak;
  final String midnight;
  final String firstthird;
  final String lastthird;

  const AlAdhanTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.midnight,
    required this.firstthird,
    required this.lastthird,
  });

  factory AlAdhanTimings.fromJson(Map<String, dynamic> json) {
    String cleanTime(dynamic value) {
      if (value == null) return '00:00';
      final str = value.toString().trim();
      // Remove timezone suffix if present (e.g., "05:12 (EEST)" -> "05:12")
      final spaceIdx = str.indexOf(' ');
      if (spaceIdx != -1) {
        return str.substring(0, spaceIdx);
      }
      return str;
    }

    return AlAdhanTimings(
      fajr: cleanTime(json['Fajr']),
      sunrise: cleanTime(json['Sunrise']),
      dhuhr: cleanTime(json['Dhuhr']),
      asr: cleanTime(json['Asr']),
      sunset: cleanTime(json['Sunset']),
      maghrib: cleanTime(json['Maghrib']),
      isha: cleanTime(json['Isha']),
      imsak: cleanTime(json['Imsak']),
      midnight: cleanTime(json['Midnight']),
      firstthird: cleanTime(json['Firstthird']),
      lastthird: cleanTime(json['Lastthird']),
    );
  }

  Map<String, String> toMap() {
    return {
      'Fajr': fajr,
      'Sunrise': sunrise,
      'Dhuhr': dhuhr,
      'Asr': asr,
      'Sunset': sunset,
      'Maghrib': maghrib,
      'Isha': isha,
      'Imsak': imsak,
      'Midnight': midnight,
      'Firstthird': firstthird,
      'Lastthird': lastthird,
    };
  }
}

/// Gregorian Date details.
class AlAdhanGregorianDate {
  final String date;
  final String format;
  final String day;
  final String weekdayEn;
  final int monthNumber;
  final String monthEn;
  final String year;

  const AlAdhanGregorianDate({
    required this.date,
    required this.format,
    required this.day,
    required this.weekdayEn,
    required this.monthNumber,
    required this.monthEn,
    required this.year,
  });

  factory AlAdhanGregorianDate.fromJson(Map<String, dynamic> json) {
    final weekday = json['weekday'] is Map ? json['weekday']['en'] as String? ?? '' : '';
    final month = json['month'] is Map ? json['month'] : {};
    return AlAdhanGregorianDate(
      date: json['date'] as String? ?? '',
      format: json['format'] as String? ?? '',
      day: json['day'] as String? ?? '',
      weekdayEn: weekday,
      monthNumber: month['number'] is int ? month['number'] as int : int.tryParse(month['number'].toString()) ?? 1,
      monthEn: month['en'] as String? ?? '',
      year: json['year'] as String? ?? '',
    );
  }
}

/// Hijri Date details.
class AlAdhanHijriDate {
  final String date;
  final String format;
  final String day;
  final String weekdayEn;
  final String weekdayAr;
  final int monthNumber;
  final String monthEn;
  final String monthAr;
  final String year;
  final List<String> holidays;

  const AlAdhanHijriDate({
    required this.date,
    required this.format,
    required this.day,
    required this.weekdayEn,
    required this.weekdayAr,
    required this.monthNumber,
    required this.monthEn,
    required this.monthAr,
    required this.year,
    required this.holidays,
  });

  factory AlAdhanHijriDate.fromJson(Map<String, dynamic> json) {
    final weekday = json['weekday'] is Map ? json['weekday'] : {};
    final month = json['month'] is Map ? json['month'] : {};
    final holidaysRaw = json['holidays'] as List? ?? [];
    
    // Parse raw API day and explicitly subtract 1 day (-1 adjustment)
    final rawDayStr = json['day'] as String? ?? ''; 
    final rawDayInt = int.tryParse(rawDayStr) ?? 15;
    final adjustedDayInt = rawDayInt > 1 ? rawDayInt - 1 : rawDayInt;
    final adjustedDayStr = adjustedDayInt.toString();

    return AlAdhanHijriDate(
      date: json['date'] as String? ?? '',
      format: json['format'] as String? ?? '',
      day: adjustedDayStr,
      weekdayEn: weekday['en'] as String? ?? '',
      weekdayAr: weekday['ar'] as String? ?? '',
      monthNumber: month['number'] is int ? month['number'] as int : int.tryParse(month['number'].toString()) ?? 1,
      monthEn: month['en'] as String? ?? '',
      monthAr: month['ar'] as String? ?? '',
      year: json['year'] as String? ?? '',
      holidays: holidaysRaw.map((e) => e.toString()).toList(),
    );
  }

  String get formattedHijri => '$day $monthEn $year AH';
}

/// Full Date information combining Gregorian & Hijri.
class AlAdhanDate {
  final String readable;
  final String timestamp;
  final AlAdhanGregorianDate gregorian;
  final AlAdhanHijriDate hijri;

  const AlAdhanDate({
    required this.readable,
    required this.timestamp,
    required this.gregorian,
    required this.hijri,
  });

  factory AlAdhanDate.fromJson(Map<String, dynamic> json) {
    return AlAdhanDate(
      readable: json['readable'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      gregorian: AlAdhanGregorianDate.fromJson(json['gregorian'] is Map<String, dynamic> ? json['gregorian'] : {}),
      hijri: AlAdhanHijriDate.fromJson(json['hijri'] is Map<String, dynamic> ? json['hijri'] : {}),
    );
  }
}

/// Calculation Method metadata.
class AlAdhanMethod {
  final int id;
  final String name;
  final Map<String, dynamic> params;

  const AlAdhanMethod({
    required this.id,
    required this.name,
    required this.params,
  });

  factory AlAdhanMethod.fromJson(Map<String, dynamic> json) {
    return AlAdhanMethod(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      params: json['params'] is Map<String, dynamic> ? json['params'] as Map<String, dynamic> : {},
    );
  }
}

/// API Response Meta details (location, timezone, method).
class AlAdhanMeta {
  final double latitude;
  final double longitude;
  final String timezone;
  final AlAdhanMethod method;
  final String latitudeAdjustmentMethod;
  final String midnightMode;
  final String school;
  final Map<String, dynamic> offset;

  const AlAdhanMeta({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.method,
    required this.latitudeAdjustmentMethod,
    required this.midnightMode,
    required this.school,
    required this.offset,
  });

  factory AlAdhanMeta.fromJson(Map<String, dynamic> json) {
    return AlAdhanMeta(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? 'UTC',
      method: AlAdhanMethod.fromJson(json['method'] is Map<String, dynamic> ? json['method'] : {}),
      latitudeAdjustmentMethod: json['latitudeAdjustmentMethod'] as String? ?? 'ANGLE_BASED',
      midnightMode: json['midnightMode'] as String? ?? 'STANDARD',
      school: json['school'] as String? ?? 'STANDARD',
      offset: json['offset'] is Map<String, dynamic> ? json['offset'] as Map<String, dynamic> : {},
    );
  }
}

/// Main data payload for prayer timings queries.
class AlAdhanTimingsData {
  final AlAdhanTimings timings;
  final AlAdhanDate date;
  final AlAdhanMeta meta;

  const AlAdhanTimingsData({
    required this.timings,
    required this.date,
    required this.meta,
  });

  factory AlAdhanTimingsData.fromJson(Map<String, dynamic> json) {
    return AlAdhanTimingsData(
      timings: AlAdhanTimings.fromJson(json['timings'] is Map<String, dynamic> ? json['timings'] : {}),
      date: AlAdhanDate.fromJson(json['date'] is Map<String, dynamic> ? json['date'] : {}),
      meta: AlAdhanMeta.fromJson(json['meta'] is Map<String, dynamic> ? json['meta'] : {}),
    );
  }
}

/// Payload for /nextPrayer endpoints.
class AlAdhanNextPrayerData {
  final String prayerName;
  final String time;

  const AlAdhanNextPrayerData({
    required this.prayerName,
    required this.time,
  });

  factory AlAdhanNextPrayerData.fromJson(Map<String, dynamic> json) {
    final key = json.keys.firstWhere((k) => k != 'date' && k != 'meta', orElse: () => 'Fajr');
    return AlAdhanNextPrayerData(
      prayerName: json['prayer'] as String? ?? key,
      time: json['time'] as String? ?? (json[key]?.toString() ?? '00:00'),
    );
  }
}
