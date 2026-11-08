import 'package:dio/dio.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:noor/core/services/prayer_times_service.dart';

class RamadanDayInfo {
  final int day;
  final String hijriDate;
  final String gregorianDate;
  final String weekday;
  final String imsak;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const RamadanDayInfo({
    required this.day,
    required this.hijriDate,
    required this.gregorianDate,
    required this.weekday,
    required this.imsak,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory RamadanDayInfo.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>? ?? {};
    final date = json['date'] as Map<String, dynamic>? ?? {};
    final hijri = date['hijri'] as Map<String, dynamic>? ?? {};
    final gregorian = date['gregorian'] as Map<String, dynamic>? ?? {};

    String cleanTime(dynamic t) {
      if (t == null) return '';
      final str = t.toString();
      final timeOnly = str.split('(').first.trim();
      return _formatTo12Hour(timeOnly);
    }

    final dayNum = int.tryParse(hijri['day']?.toString() ?? '1') ?? 1;

    String weekdayArabic = '';
    final weekdayMap = hijri['weekday'] as Map<String, dynamic>?;
    if (weekdayMap != null && weekdayMap['ar'] != null) {
      weekdayArabic = weekdayMap['ar'].toString();
    } else {
      final en = gregorian['weekday']?['en']?.toString().toLowerCase() ?? '';
      weekdayArabic = _translateWeekday(en);
    }

    return RamadanDayInfo(
      day: dayNum,
      hijriDate: hijri['date']?.toString() ?? '',
      gregorianDate: gregorian['date']?.toString() ?? '',
      weekday: weekdayArabic,
      imsak: cleanTime(timings['Imsak']),
      fajr: cleanTime(timings['Fajr']),
      sunrise: cleanTime(timings['Sunrise']),
      dhuhr: cleanTime(timings['Dhuhr']),
      asr: cleanTime(timings['Asr']),
      maghrib: cleanTime(timings['Maghrib']),
      isha: cleanTime(timings['Isha']),
    );
  }

  static String _formatTo12Hour(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final hour = int.tryParse(parts[0]);
    final minute = parts[1];
    if (hour == null) return time24;

    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'م' : 'ص';
    return '$hour12:$minute $period';
  }

  static String _translateWeekday(String en) {
    switch (en) {
      case 'saturday':
        return 'السبت';
      case 'sunday':
        return 'الأحد';
      case 'monday':
        return 'الاثنين';
      case 'tuesday':
        return 'الثلاثاء';
      case 'wednesday':
        return 'الأربعاء';
      case 'thursday':
        return 'الخميس';
      case 'friday':
        return 'الجمعة';
      default:
        return '';
    }
  }
}

class RamadanApiService {
  final Dio _dio;

  RamadanApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  Future<List<RamadanDayInfo>> fetchRamadanCalendar({
    double? latitude,
    double? longitude,
  }) async {
    final coords = PrayerTimesService().currentCoordinates;
    final lat = latitude ?? coords.latitude;
    final lng = longitude ?? coords.longitude;

    HijriCalendar.setLocal('ar');
    final hijriNow = HijriCalendar.now();
    final currentHijriYear =
        hijriNow.hMonth > 9 ? hijriNow.hYear + 1 : hijriNow.hYear;

    final url =
        'https://api.aladhan.com/v1/hijriCalendar?latitude=$lat&longitude=$lng&method=4&month=9&year=$currentHijriYear';

    final response = await _dio.get(url);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] as List<dynamic>?;
      if (data != null) {
        return data
            .map((item) => RamadanDayInfo.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception('فشل في جلب إمساكية شهر رمضان المبارك');
  }
}
