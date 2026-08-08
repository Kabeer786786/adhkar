import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/network/aladhan_api_client.dart';
import 'package:adhkar/features/prayer/data/models/aladhan_models.dart';
import 'package:adhkar/features/prayer/data/repositories/aladhan_repository.dart';

void main() {
  group('AlAdhan Models Serialization Tests', () {
    test('AlAdhanTimings parses HH:mm format and cleans timezone suffixes', () {
      final json = {
        'Fajr': '04:30 (EEST)',
        'Sunrise': '06:00',
        'Dhuhr': '12:15',
        'Asr': '15:45',
        'Sunset': '18:30',
        'Maghrib': '18:30 (+03)',
        'Isha': '20:00',
        'Imsak': '04:15',
        'Midnight': '00:15',
        'Firstthird': '22:10',
        'Lastthird': '02:20',
      };

      final timings = AlAdhanTimings.fromJson(json);

      expect(timings.fajr, '04:30');
      expect(timings.sunrise, '06:00');
      expect(timings.dhuhr, '12:15');
      expect(timings.asr, '15:45');
      expect(timings.maghrib, '18:30');
      expect(timings.isha, '20:00');
    });

    test('AlAdhanApiResponse parses 200 OK response structure correctly', () {
      final rawJson = {
        'code': 200,
        'status': 'OK',
        'data': {
          'timings': {
            'Fajr': '04:30',
            'Sunrise': '06:00',
            'Dhuhr': '12:15',
            'Asr': '15:45',
            'Sunset': '18:30',
            'Maghrib': '18:30',
            'Isha': '20:00',
            'Imsak': '04:15',
            'Midnight': '00:15',
            'Firstthird': '22:10',
            'Lastthird': '02:20',
          },
          'date': {
            'readable': '29 Jul 2026',
            'timestamp': '1785283200',
            'gregorian': {
              'date': '29-07-2026',
              'format': 'DD-MM-YYYY',
              'day': '29',
              'weekday': {'en': 'Wednesday'},
              'month': {'number': 7, 'en': 'July'},
              'year': '2026'
            },
            'hijri': {
              'date': '14-02-1448',
              'format': 'DD-MM-YYYY',
              'day': '14',
              'weekday': {'en': 'Al Arba\'a', 'ar': 'الاربعاء'},
              'month': {'number': 2, 'en': 'Safar', 'ar': 'صَفَر'},
              'year': '1448',
              'holidays': []
            }
          },
          'meta': {
            'latitude': 21.4225,
            'longitude': 39.8262,
            'timezone': 'Asia/Riyadh',
            'method': {'id': 4, 'name': 'Umm Al-Qura University, Makkah', 'params': {}},
            'latitudeAdjustmentMethod': 'ANGLE_BASED',
            'midnightMode': 'STANDARD',
            'school': 'STANDARD',
            'offset': {}
          }
        }
      };

      final response = AlAdhanApiResponse<AlAdhanTimingsData>.fromJson(
        rawJson,
        (json) => AlAdhanTimingsData.fromJson(json as Map<String, dynamic>),
      );

      expect(response.isSuccess, true);
      expect(response.code, 200);
      expect(response.data.timings.fajr, '04:30');
      expect(response.data.date.gregorian.monthEn, 'July');
      expect(response.data.date.hijri.monthEn, 'Safar');
      expect(response.data.meta.latitude, 21.4225);
    });

    test('Parses Mysore, India AlAdhan API response correctly', () {
      final rawMysoreJson = {
        "code": 200,
        "status": "OK",
        "data": {
          "timings": {
            "Fajr": "04:54",
            "Sunrise": "06:09",
            "Dhuhr": "12:30",
            "Asr": "16:58",
            "Sunset": "18:51",
            "Maghrib": "18:51",
            "Isha": "20:06",
            "Imsak": "04:44",
            "Midnight": "00:30",
            "Firstthird": "22:37",
            "Lastthird": "02:23"
          },
          "date": {
            "readable": "29 Jul 2026",
            "timestamp": "1785288600",
            "hijri": {
              "date": "15-02-1448",
              "format": "DD-MM-YYYY",
              "day": "15",
              "weekday": {"en": "Al Arba'a", "ar": "الاربعاء"},
              "month": {"number": 2, "en": "Ṣafar", "ar": "صَفَر", "days": 30},
              "year": "1448",
              "holidays": []
            },
            "gregorian": {
              "date": "29-07-2026",
              "format": "DD-MM-YYYY",
              "day": "29",
              "weekday": {"en": "Wednesday"},
              "month": {"number": 7, "en": "July"},
              "year": "2026"
            }
          },
          "meta": {
            "latitude": 12.2958,
            "longitude": 76.6394,
            "timezone": "Asia/Kolkata",
            "method": {
              "id": 1,
              "name": "University of Islamic Sciences, Karachi",
              "params": {"Fajr": 18, "Isha": 18}
            },
            "latitudeAdjustmentMethod": "ANGLE_BASED",
            "midnightMode": "STANDARD",
            "school": "HANAFI",
            "offset": {}
          }
        }
      };

      final response = AlAdhanApiResponse<AlAdhanTimingsData>.fromJson(
        rawMysoreJson,
        (json) => AlAdhanTimingsData.fromJson(json as Map<String, dynamic>),
      );

      expect(response.isSuccess, true);
      expect(response.data.timings.fajr, '04:54');
      expect(response.data.timings.sunrise, '06:09');
      expect(response.data.timings.dhuhr, '12:30');
      expect(response.data.timings.asr, '16:58');
      expect(response.data.timings.maghrib, '18:51');
      expect(response.data.timings.isha, '20:06');
      expect(response.data.date.hijri.monthEn, 'Ṣafar');
      expect(response.data.meta.timezone, 'Asia/Kolkata');
      expect(response.data.meta.school, 'HANAFI');
    });
  });

  group('AlAdhanApiClient Parameter Helper Tests', () {
    test('Date formatting outputs DD-MM-YYYY', () {
      final date = DateTime(2026, 7, 29);
      final formatted = AlAdhanApiClient.formatDate(date);
      expect(formatted, '29-07-2026');
    });

    test('Method mapping resolves correct IDs', () {
      expect(AlAdhanApiClient.mapMethodToId('MWL'), 3);
      expect(AlAdhanApiClient.mapMethodToId('ISNA'), 2);
      expect(AlAdhanApiClient.mapMethodToId('EGYPT'), 5);
      expect(AlAdhanApiClient.mapMethodToId('MAKKAH'), 4);
      expect(AlAdhanApiClient.mapMethodToId('KARACHI'), 1);
      expect(AlAdhanApiClient.mapMethodToId('TEHRAN'), 7);
      expect(AlAdhanApiClient.mapMethodToId('GULF'), 8);
    });

    test('Juristic school mapping resolves 0 for Shafi/Standard and 1 for Hanafi', () {
      expect(AlAdhanApiClient.mapJuristicToSchool('Standard'), 0);
      expect(AlAdhanApiClient.mapJuristicToSchool('Shafi'), 0);
      expect(AlAdhanApiClient.mapJuristicToSchool('Hanafi'), 1);
    });
  });

  group('AlAdhanRepository Fallback Tests', () {
    test('Repository falls back to local PrayerCalculationService when API is unavailable or fails', () async {
      final repo = AlAdhanRepository();
      final testDate = DateTime(2026, 7, 29);

      // Coordinates for Makkah
      final fetchResult = await repo.getPrayerTimes(
        date: testDate,
        latitude: 21.4225,
        longitude: 39.8262,
        methodName: 'MAKKAH',
      );

      expect(fetchResult.result.fajr.isBefore(fetchResult.result.sunrise), true);
      expect(fetchResult.result.sunrise.isBefore(fetchResult.result.dhuhr), true);
      expect(fetchResult.result.dhuhr.isBefore(fetchResult.result.asr), true);
      expect(fetchResult.result.asr.isBefore(fetchResult.result.maghrib), true);
      expect(fetchResult.result.maghrib.isBefore(fetchResult.result.isha), true);
    });
  });
}
