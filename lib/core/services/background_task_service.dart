import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'prayer_times_service.dart';
import 'widget_service.dart';

const String prayerSyncTaskKey = 'noor_prayer_sync_task';
const String periodicPrayerSyncTaskName = 'noor_periodic_prayer_sync';

/// دالة المستوى الأعلى لتنفيذ المهام الدورية في الخلفية عبر WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[Workmanager] بدء تنفيذ مهمة الخلفية: $task');

    try {
      final prefs = await SharedPreferences.getInstance();
      final double lat = prefs.getDouble('last_latitude') ??
          PrayerTimesService.defaultLatitude;
      final double lng = prefs.getDouble('last_longitude') ??
          PrayerTimesService.defaultLongitude;
      final now = DateTime.now();

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      // جلب بيانات الشهر الحالي من Aladhan API مع method=5 (الهيئة المصرية العامة للمساحة)
      final url =
          'https://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$lng&method=5&month=${now.month}&year=${now.year}';
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          final cacheKey = 'prayer_calendar_${now.year}_${now.month}';
          await prefs.setString(cacheKey, jsonEncode(data));
          debugPrint(
              '[Workmanager] تم تحديث كاش مواقيت الصلاة لشهر ${now.month}/${now.year} بنجاح.');
        }
      }

      // إذا كان الوقت قرب نهاية الشهر (اليوم 25 فما فوق)، جلب تقويم الشهر القادم أيضاً
      if (now.day >= 25) {
        try {
          final nextMonthDate = DateTime(now.year, now.month + 1, 1);
          final nextUrl =
              'https://api.aladhan.com/v1/calendar?latitude=$lat&longitude=$lng&method=5&month=${nextMonthDate.month}&year=${nextMonthDate.year}';
          final nextResponse = await dio.get(nextUrl);
          if (nextResponse.statusCode == 200 && nextResponse.data != null) {
            final nextData = nextResponse.data['data'] as List<dynamic>?;
            if (nextData != null && nextData.isNotEmpty) {
              final nextCacheKey =
                  'prayer_calendar_${nextMonthDate.year}_${nextMonthDate.month}';
              await prefs.setString(nextCacheKey, jsonEncode(nextData));
              debugPrint('[Workmanager] تم تحديث كاش مواقيت الشهر القادم بنجاح.');
            }
          }
        } catch (e) {
          debugPrint('[Workmanager] تعذر جلب تقويم الشهر القادم: $e');
        }
      }

      // إعادة جدولة إشعارات الأذان المجدولة في نظام الأندرويد بناءً على المواقيت الجديدة
      final notifService = NotificationService();
      await notifService.initialize();
      await notifService.scheduleUpcomingPrayerNotifications(daysAhead: 7);
      await notifService.scheduleSpiritualReminders();

      // تحديث ودجتس الشاشة الرئيسية وشاشة القفل بالموعد الجديد للصلاة
      try {
        final prayerService = PrayerTimesService();
        final nextPrayer = prayerService.getNextPrayer();
        final int hour24 = nextPrayer.time.hour;
        final int hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
        final String period = hour24 >= 12 ? 'م' : 'ص';
        final String minute = nextPrayer.time.minute.toString().padLeft(2, '0');
        final String formattedTime = '$hour12:$minute $period';

        await WidgetService.updatePrayerWidget(nextPrayer.name, formattedTime);
        await WidgetService.updateAsmaAlHusnaWidget();
      } catch (widgetError) {
        debugPrint('[Workmanager] تعذر تحديث الودجتس في مهمة الخلفية: $widgetError');
      }

      debugPrint('[Workmanager] اكتملت مهمة الخلفية بنجاح.');
      return true;
    } catch (e) {
      debugPrint('[Workmanager] حدث خطأ أثناء تنفيذ مهمة الخلفية: $e');
      return false;
    }
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  bool _isInitialized = false;

  /// تهيئة Workmanager وتسجيل المهمة الدورية لتحديث المواقيت والإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    // لا يتم تفعيل Workmanager إلا في بيئة الهاتف الحقيقية (Android / iOS)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint(
          '[Workmanager] بيئة التشغيل الحالية ليست هاتفاً محمولاً، تم تخطي التهيئة.');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      // تسجيل مهمة دورية تعمل كل 12 ساعة مع اشتراط توفر اتصال بالشبكة
      await Workmanager().registerPeriodicTask(
        prayerSyncTaskKey,
        periodicPrayerSyncTaskName,
        frequency: const Duration(hours: 12),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

      _isInitialized = true;
      debugPrint('[Workmanager] تم تهيئة خدمة المهام الخلفية وجدولة المهمة الدورية بنجاح.');
    } catch (e) {
      debugPrint('[Workmanager] تعذر تهيئة المهام الخلفية: $e');
    }
  }
}
