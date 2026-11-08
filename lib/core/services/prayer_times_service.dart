import 'dart:async';
import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NextPrayerInfo {
  final String name;
  final DateTime time;
  final Duration remaining;

  NextPrayerInfo({
    required this.name,
    required this.time,
    required this.remaining,
  });
}

class HijriDateInfo {
  final String day;
  final String monthName;
  final String year;
  final String weekdayName;
  final List<String> holidays;

  const HijriDateInfo({
    required this.day,
    required this.monthName,
    required this.year,
    required this.weekdayName,
    this.holidays = const [],
  });

  String get fullDate => '$weekdayName، $day $monthName $year هـ';
}

class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal() {
    _loadSavedCoordinates();
    _loadHijriDateFromPrefs();
  }

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  // إحداثيات القاهرة الافتراضية كقيمة احتياطية في حال تعذر الحصول على الموقع
  static const double defaultLatitude = 30.0444;
  static const double defaultLongitude = 31.2357;

  Coordinates _currentCoordinates =
      Coordinates(defaultLatitude, defaultLongitude);
  String _cityName = 'القاهرة';
  String _countryName = 'مصر';
  String _locationName = 'القاهرة، مصر';

  Coordinates get currentCoordinates => _currentCoordinates;
  String get cityName => _cityName;
  String get countryName => _countryName;
  String get locationName => _locationName;

  List<dynamic>? _cachedMonthData;
  HijriDateInfo? _todayHijriDate;

  HijriDateInfo get todayHijriDate => _todayHijriDate ?? _getFallbackHijriDate();

  /// جدول ترجمة أشهر المناسبات الإسلامية من الإنجليزية إلى العربية
  static const Map<String, String> holidaysTranslation = {
    '1st of Ramadan': 'أول أيام شهر رمضان المبارك',
    'Ramadan': 'شهر رمضان المبارك',
    'Eid al-Fitr': 'عيد الفطر المبارك',
    'Eid-ul-Fitr': 'عيد الفطر المبارك',
    'Arafat': 'يوم عرفة',
    'Day of Arafah': 'يوم عرفة',
    'Eid al-Adha': 'عيد الأضحى المبارك',
    'Eid-ul-Adha': 'عيد الأضحى المبارك',
    'Ashura': 'يوم عاشوراء',
    'Day of Ashura': 'يوم عاشوراء',
    'Tasua': 'تاسوعاء',
    'Mawlid al-Nabi': 'المولد النبوي الشريف',
    'Mawlid': 'المولد النبوي الشريف',
    'Prophet\'s Birthday': 'المولد النبوي الشريف',
    'Isra and Mi\'raj': 'الإسراء والمعراج',
    'Al-Isra wal-Mi\'raj': 'الإسراء والمعراج',
    'Laylat al-Qadr': 'ليلة القدر',
    'Islamic New Year': 'رأس السنة الهجرية',
    '1st of Muharram': 'بداية السنة الهجرية الجديدة',
    'Mid-Sha\'ban': 'ليلة النصف من شعبان',
    'Nisf Sha\'ban': 'ليلة النصف من شعبان',
  };

  /// ترجمة اسم المناسبة إلى العربية
  static String translateHoliday(String holiday) {
    final trimmed = holiday.trim();
    for (final entry in holidaysTranslation.entries) {
      if (trimmed.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return trimmed;
  }

  HijriDateInfo _getFallbackHijriDate() {
    try {
      HijriCalendar.setLocal('ar');
      final hijri = HijriCalendar.now();
      return HijriDateInfo(
        day: hijri.hDay.toString(),
        monthName: hijri.longMonthName,
        year: hijri.hYear.toString(),
        weekdayName: hijri.getDayName(),
        holidays: const [],
      );
    } catch (_) {
      return const HijriDateInfo(
        day: '',
        monthName: '',
        year: '',
        weekdayName: '',
        holidays: [],
      );
    }
  }

  void _extractAndCacheHijriDate(List<dynamic> monthData, [DateTime? date]) {
    final now = date ?? DateTime.now();
    for (final dayItem in monthData) {
      final dateObj = dayItem['date'] as Map<String, dynamic>?;
      final gregorian = dateObj?['gregorian'] as Map<String, dynamic>?;
      final dayNum = int.tryParse(gregorian?['day']?.toString() ?? '');

      if (dayNum == now.day) {
        final hijri = dateObj?['hijri'] as Map<String, dynamic>?;
        if (hijri != null) {
          final day = hijri['day']?.toString() ?? '${now.day}';
          final monthObj = hijri['month'] as Map<String, dynamic>?;
          final monthName = monthObj?['ar']?.toString() ??
              monthObj?['en']?.toString() ??
              '';
          final year = hijri['year']?.toString() ?? '';
          final weekdayObj = hijri['weekday'] as Map<String, dynamic>?;
          final weekdayName = weekdayObj?['ar']?.toString() ??
              weekdayObj?['en']?.toString() ??
              '';

          final rawHolidays = hijri['holidays'] as List<dynamic>? ?? [];
          final List<String> translatedHolidays = [];
          for (final h in rawHolidays) {
            if (h != null && h.toString().trim().isNotEmpty) {
              final translated = translateHoliday(h.toString());
              if (!translatedHolidays.contains(translated)) {
                translatedHolidays.add(translated);
              }
            }
          }

          _todayHijriDate = HijriDateInfo(
            day: day,
            monthName: monthName,
            year: year,
            weekdayName: weekdayName,
            holidays: translatedHolidays,
          );

          unawaited(_saveHijriDateToPrefs(_todayHijriDate!));
          return;
        }
      }
    }
  }

  Future<void> _loadSavedCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lng = prefs.getDouble('last_longitude');
      final city = prefs.getString('last_city_name');
      final country = prefs.getString('last_country_name');
      final loc = prefs.getString('last_location_name');
      if (lat != null && lng != null) {
        _currentCoordinates = Coordinates(lat, lng);
      }
      if (city != null && city.isNotEmpty) _cityName = city;
      if (country != null && country.isNotEmpty) _countryName = country;
      if (loc != null && loc.isNotEmpty) _locationName = loc;
    } catch (_) {}
  }

  Future<void> _saveLocationToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', _currentCoordinates.latitude);
      await prefs.setDouble('last_longitude', _currentCoordinates.longitude);
      await prefs.setString('last_city_name', _cityName);
      await prefs.setString('last_country_name', _countryName);
      await prefs.setString('last_location_name', _locationName);
    } catch (_) {}
  }

  Future<void> _saveHijriDateToPrefs(HijriDateInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hijri_cached_day', info.day);
      await prefs.setString('hijri_cached_month', info.monthName);
      await prefs.setString('hijri_cached_year', info.year);
      await prefs.setString('hijri_cached_weekday', info.weekdayName);
      await prefs.setStringList('hijri_cached_holidays', info.holidays);
    } catch (_) {}
  }

  Future<void> _loadHijriDateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final day = prefs.getString('hijri_cached_day');
      final month = prefs.getString('hijri_cached_month');
      final year = prefs.getString('hijri_cached_year');
      final weekday = prefs.getString('hijri_cached_weekday');
      final holidays = prefs.getStringList('hijri_cached_holidays') ?? [];

      if (day != null && month != null && year != null && weekday != null) {
        _todayHijriDate = HijriDateInfo(
          day: day,
          monthName: month,
          year: year,
          weekdayName: weekday,
          holidays: holidays,
        );
      }
    } catch (_) {}
  }

  /// طلب إذن الموقع الجغرافي برمجياً وبشكل صريح
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[مواقيت الصلاة] جاري إظهار نافذة طلب إذن الموقع للمستخدم...');
        permission = await Geolocator.requestPermission();
        debugPrint('[مواقيت الصلاة] نتيجة طلب إذن الموقع: $permission');
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('[مواقيت الصلاة] خطأ أثناء طلب إذن الموقع: $e');
      return false;
    }
  }

  /// فحص الإذن وجلب الإحداثيات الحالية للمستخدم مع اسم المدينة والدولة
  Future<Coordinates> updateUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
            '[مواقيت الصلاة] لم يتم منح إذن الموقع، سيتم اعتماد إحداثيات القاهرة.');
        return _currentCoordinates;
      }

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[مواقيت الصلاة] خدمات الموقع الجغرافي GPS معطلة في الجهاز.');
        return _currentCoordinates;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      _currentCoordinates = Coordinates(position.latitude, position.longitude);
      debugPrint(
          '[مواقيت الصلاة] تم تحديث موقع المستخدم بنجاح: (${position.latitude}, ${position.longitude})');

      try {
        final geocoding = Geocoding();
        final List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final locality = (place.locality != null && place.locality!.isNotEmpty)
              ? place.locality!
              : ((place.subAdministrativeArea != null &&
                      place.subAdministrativeArea!.isNotEmpty)
                  ? place.subAdministrativeArea!
                  : (place.administrativeArea ?? ''));
          final country = place.country ?? '';

          if (locality.isNotEmpty && country.isNotEmpty) {
            _cityName = locality;
            _countryName = country;
            _locationName = '$_cityName، $_countryName';
          } else if (country.isNotEmpty) {
            _countryName = country;
            _locationName = _countryName;
          } else if (locality.isNotEmpty) {
            _cityName = locality;
            _locationName = _cityName;
          }
          debugPrint('[مواقيت الصلاة] تم جلب وحفظ اسم الموقع بنجاح: $_locationName');
          await _saveLocationToPrefs();
        } else {
          await _saveLocationToPrefs();
        }
      } catch (geocodingError) {
        debugPrint(
            '[مواقيت الصلاة] تعذر جلب اسم المدينة والدولة عبر geocoding ($geocodingError).');
        await _saveLocationToPrefs();
      }

      return _currentCoordinates;
    } catch (e) {
      debugPrint(
          '[مواقيت الصلاة] خطأ أثناء جلب الموقع الجغرافي: $e. الاعتماد على الإحداثيات الافتراضية.');
      return _currentCoordinates;
    }
  }

  /// مفتاح الكاش لشهر وسنة معينة
  String _getCacheKey(int year, int month) => 'prayer_calendar_${year}_$month';

  /// تحميل بيانات الشهر الحالي من الكاش أولاً (Offline-First)، ثم المزامنة الصامتة عبر الإنترنت
  Future<void> initializeAndCacheCalendar({DateTime? targetDate}) async {
    final now = targetDate ?? DateTime.now();
    final cacheKey = _getCacheKey(now.year, now.month);

    // استرجاع التاريخ الهجري والإحداثيات المحفوظة مسبقاً بشكل فوري
    await _loadSavedCoordinates();
    await _loadHijriDateFromPrefs();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        _cachedMonthData = jsonDecode(cachedJson) as List<dynamic>;
        _extractAndCacheHijriDate(_cachedMonthData!, now);
        debugPrint(
            '[مواقيت الصلاة] تم استرجاع مواقيت شهر ${now.month}/${now.year} من الكاش المحلي بنجاح (Offline).');
      }
    } catch (e) {
      debugPrint('[مواقيت الصلاة] خطأ أثناء قراءة الكاش المحلي: $e');
    }

    // إذا لم تتوفر البيانات محلياً، أو لمزامنة التحديثات، يتم استدعاء الـ API في الخلفية
    await syncCalendarSilently(targetDate: now);
  }

  /// مزامنة صامتة للتقويم الشهري عبر Aladhan API وحفظه في SharedPreferences مع method=5
  Future<void> syncCalendarSilently({DateTime? targetDate}) async {
    final now = targetDate ?? DateTime.now();
    final cacheKey = _getCacheKey(now.year, now.month);

    try {
      final lat = _currentCoordinates.latitude;
      final lng = _currentCoordinates.longitude;
      // method=5 يمثل الهيئة المصرية العامة للمساحة لدقة مواقيت الصلاة في مصر
      final url =
          'https://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$lng&method=5&month=${now.month}&year=${now.year}';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          _cachedMonthData = data;
          _extractAndCacheHijriDate(data, now);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(data));
          debugPrint(
              '[مواقيت الصلاة] تم جلب وتحديث تقويم شهر ${now.month}/${now.year} بنجاح من Aladhan API (method=5) وحفظه بالكاش.');
        }
      }

      // إذا كان الوقت قرب نهاية الشهر (اليوم 25 فما فوق)، جلب تقويم الشهر القادم أيضاً
      if (now.day >= 25) {
        try {
          final nextMonthDate = DateTime(now.year, now.month + 1, 1);
          final nextCacheKey =
              _getCacheKey(nextMonthDate.year, nextMonthDate.month);
          final nextUrl =
              'https://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$lng&method=5&month=${nextMonthDate.month}&year=${nextMonthDate.year}';
          final nextResponse = await _dio.get(nextUrl);
          if (nextResponse.statusCode == 200 && nextResponse.data != null) {
            final nextData = nextResponse.data['data'] as List<dynamic>?;
            if (nextData != null && nextData.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(nextCacheKey, jsonEncode(nextData));
              debugPrint(
                  '[مواقيت الصلاة] تم جلب وحفظ تقويم الشهر القادم في الكاش بنجاح.');
            }
          }
        } catch (e) {
          debugPrint('[مواقيت الصلاة] تعذر جلب تقويم الشهر القادم: $e');
        }
      }
    } catch (e) {
      debugPrint(
          '[مواقيت الصلاة] تعذر الاتصال بـ Aladhan API ($e)، الاستمرار بالبيانات المخزنة محلياً.');
    }
  }

  DateTime? _parseTiming(int year, int month, int day, dynamic timingStr) {
    if (timingStr == null) return null;
    final clean = timingStr.toString().split('(').first.trim();
    final parts = clean.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(year, month, day, hour, minute);
  }

  /// جلب مواقيت الصلاة ليوم محدد من الكاش/الـ API إن توفرت، أو حسابها محلياً عبر adhan
  Map<String, DateTime> getTodayPrayerTimes([DateTime? date]) {
    final now = date ?? DateTime.now();

    if (_cachedMonthData != null && _cachedMonthData!.isNotEmpty) {
      for (final dayItem in _cachedMonthData!) {
        final dateObj = dayItem['date'] as Map<String, dynamic>?;
        final gregorian = dateObj?['gregorian'] as Map<String, dynamic>?;
        final dayNum = int.tryParse(gregorian?['day']?.toString() ?? '');

        if (dayNum == now.day) {
          final timings = dayItem['timings'] as Map<String, dynamic>?;
          if (timings != null) {
            final fajr = _parseTiming(now.year, now.month, now.day, timings['Fajr']);
            final sunrise =
                _parseTiming(now.year, now.month, now.day, timings['Sunrise']);
            final dhuhr =
                _parseTiming(now.year, now.month, now.day, timings['Dhuhr']);
            final asr = _parseTiming(now.year, now.month, now.day, timings['Asr']);
            final maghrib =
                _parseTiming(now.year, now.month, now.day, timings['Maghrib']);
            final isha =
                _parseTiming(now.year, now.month, now.day, timings['Isha']);

            if (fajr != null &&
                sunrise != null &&
                dhuhr != null &&
                asr != null &&
                maghrib != null &&
                isha != null) {
              return {
                'الفجر': fajr,
                'الشروق': sunrise,
                'الظهر': dhuhr,
                'العصر': asr,
                'المغرب': maghrib,
                'العشاء': isha,
              };
            }
          }
        }
      }
    }

    // بديل احتياطي فوري غير معتمد على الإنترنت عبر حزمة adhan
    final prayerTimes = getPrayerTimesForDate(now);
    return {
      'الفجر': prayerTimes.fajr,
      'الشروق': prayerTimes.sunrise,
      'الظهر': prayerTimes.dhuhr,
      'العصر': prayerTimes.asr,
      'المغرب': prayerTimes.maghrib,
      'العشاء': prayerTimes.isha,
    };
  }

  /// حساب مواقيت الصلاة ليوم محدد باستخدام حزمة adhan (احتياطي دون إنترنت)
  PrayerTimes getPrayerTimesForDate(DateTime date, [Coordinates? coordinates]) {
    final coords = coordinates ?? _currentCoordinates;
    final dateComponents = DateComponents.from(date);
    final CalculationParameters params =
        CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes(coords, dateComponents, params);
  }

  /// تحديد الصلاة القادمة والوقت المتبقي لها بدقة استناداً إلى بيانات التقويم
  NextPrayerInfo getNextPrayer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    final todayMap = getTodayPrayerTimes(now);

    // التحقق من الصلوات المتبقية اليوم بالترتيب الزمني
    const prayersOrder = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    for (final name in prayersOrder) {
      final time = todayMap[name];
      if (time != null && time.isAfter(now)) {
        return NextPrayerInfo(
          name: name,
          time: time,
          remaining: time.difference(now),
        );
      }
    }

    // إذا انتهت صلوات اليوم، فالصلاة القادمة هي فجر اليوم التالي
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowMap = getTodayPrayerTimes(tomorrow);
    final tomorrowFajr = tomorrowMap['الفجر'] ??
        getPrayerTimesForDate(tomorrow).fajr;

    return NextPrayerInfo(
      name: 'الفجر',
      time: tomorrowFajr,
      remaining: tomorrowFajr.difference(now),
    );
  }
}
