import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// دالة المستوى الأعلى لمعالجة استجابات الإشعارات في الخلفية لضمان عملها بعد إغلاق التطبيق
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
      '[الإشعارات في الخلفية] تم استقبال تفاعل الإشعار بنجاح: ${notificationResponse.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات وجلب المنطقة الزمنية الخاصة بجهاز المستخدم تلقائياً
  Future<void> initialize() async {
    if (_isInitialized) return;

    // تهيئة قاعدة بيانات المناطق الزمنية
    tz.initializeTimeZones();
    try {
      // جلب المنطقة الزمنية للهاتف برمجياً عبر flutter_timezone
      final TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTimeZone = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint('[الإشعارات] تم ضبط المنطقة الزمنية للجهاز بنجاح على: $currentTimeZone');
    } catch (e) {
      debugPrint('[الإشعارات] تعذر جلب المنطقة الزمنية للجهاز تلقائياً: $e. الاعتماد على Africa/Cairo كقيمة احتياطية.');
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_name');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[الإشعارات] تم التفاعل مع الإشعار: ${response.payload}');
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _isInitialized = true;
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
          'prayer_channel_v2',
          'تنبيهات أذان الصلاة',
          description: 'إشعارات ومنبهات مواقيت الصلاة ذات الأولوية القصوى التي تخترق الصامت',
          importance: Importance.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(prayerChannel);

        const AndroidNotificationChannel spiritualChannel = AndroidNotificationChannel(
          'spiritual_reminders_channel',
          'التذكيرات الروحانية',
          description: 'تنبيهات أذكار الصباح والمساء والورد القرآني وسنن يوم الجمعة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(spiritualChannel);
      }
      debugPrint('[الإشعارات] تم تهيئة خدمة الإشعارات بنجاح.');
    } catch (e) {
      debugPrint('[الإشعارات] تعذر تهيئة الإشعارات في البيئة الحالية: $e');
    }
  }

  /// طلب الصلاحيات برمجياً وقت التشغيل مع معالجة المنبهات الدقيقة لأندرويد 13 و 14+
  Future<void> requestPermissions() async {
    await initialize();

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // 1. طلب إذن الإشعارات لأندرويد 13+ عبر الدالة الأصلية لحزمة الإشعارات لضمان ظهور النافذة
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        debugPrint('[الإشعارات] نتيجة طلب إذن الإشعارات عبر منصة أندرويد: $granted');

        // 2. التحقق من إذن المنبهات الدقيقة (SCHEDULE_EXACT_ALARM)
        final canScheduleExact = await androidImplementation.canScheduleExactNotifications();
        debugPrint('[الإشعارات] هل يسمح النظام بالمنبهات الدقيقة حالياً؟ $canScheduleExact');

        if (canScheduleExact == false) {
          // فتح شاشة الإعدادات الخاصة بتمكين المنبهات والتذكيرات الدقيقة للمستخدم
          await androidImplementation.requestExactAlarmsPermission();
        }
      }

      // طلب إضافي عبر permission_handler للتحقق الشامل
      final exactStatus = await Permission.scheduleExactAlarm.status;
      if (!exactStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('[الإشعارات] تعذر طلب الصلاحيات في البيئة الحالية: $e');
    }
  }

  /// طلب إذن المنبهات الدقيقة المخصص لأندرويد 13 فما فوق
  Future<PermissionStatus> requestScheduleExactAlarm() async {
    final status = await Permission.scheduleExactAlarm.request();
    debugPrint('[الصلاحيات] نتيجة طلب إذن المنبهات الدقيقة (Exact Alarm): $status');
    return status;
  }

  /// طلب إذن استثناء التطبيق من قيود توفير طاقة البطارية (Doze Mode)
  Future<PermissionStatus> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    debugPrint('[الصلاحيات] نتيجة طلب إذن تجاهل تحسينات البطارية: $status');
    return status;
  }

  /// طلب كافة صلاحيات استقرار عمل الأذان في الخلفية بشكل متتابع وصريح
  Future<bool> requestBackgroundPrayerPermissions() async {
    await requestPermissions();
    final alarmStatus = await requestScheduleExactAlarm();
    final batteryStatus = await requestIgnoreBatteryOptimizations();

    final isGranted = alarmStatus.isGranted || batteryStatus.isGranted;
    debugPrint('[الصلاحيات] حالة صلاحيات عمل الأذان بالخلفية: $isGranted');
    return isGranted;
  }

  /// جدولة تنبيه مخصص بالكامل لمهمة محددة باسمها ووقتها المحدد
  Future<void> scheduleTaskNotification({
    required int id,
    required String taskName,
    required DateTime scheduledTime,
    String title = 'تذكير بمهام نور',
    String? customBody,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      debugPrint('[الإشعارات] الوقت المحدد في الماضي، تم تخطي الجدولة.');
      return;
    }

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledTime, tz.local);
    final String body = customBody ?? 'حان الآن وقت: $taskName';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'noor_tasks_channel',
      'تنبيهات مهام نور',
      channelDescription: 'إشعارات وتنبيهات المهام والعادات اليومية في تطبيق نور',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // محاولة الجدولة الدقيقة أولاً
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[الإشعارات] تمت جدولة التنبيه بنجاح للمهمة "$taskName" برقم ($id) في: $scheduledTime');
    } catch (exactError) {
      debugPrint('[الإشعارات] تعذر استخدام الجدولة الدقيقة ($exactError)، جاري التبديل التلقائي للجدولة البديلة.');
      try {
        // بديل تلقائي في حال عدم توفر إذن SCHEDULE_EXACT_ALARM لضمان وصول التنبيه
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('[الإشعارات] تمت جدولة التنبيه بالوضع البديل بنجاح للمهمة "$taskName" برقم ($id).');
      } catch (fallbackError) {
        debugPrint('[الإشعارات] فشلت جدولة التنبيه نهائياً: $fallbackError');
      }
    }
  }

  /// إلغاء إشعار محدد لمهمة معينة باستخدام معرّفها الخاص
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
      debugPrint('[الإشعارات] تم إلغاء التنبيه الخاص بالمهمة ذات المعرّف: $id');
    } catch (e) {
      debugPrint('[الإشعارات] تعذر إلغاء التنبيه: $e');
    }
  }

  /// إلغاء كافة الإشعارات المجدولة
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[الإشعارات] تم إلغاء كافة التنبيهات المجدولة.');
    } catch (e) {
      debugPrint('[الإشعارات] تعذر إلغاء كافة التنبيهات: $e');
    }
  }

  /// جدولة إشعارات مواقيت الصلاة للأيام القادمة مسبقاً من الكاش المحلي
  Future<void> scheduleUpcomingPrayerNotifications({int daysAhead = 7}) async {
    await initialize();

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cacheKey = 'prayer_calendar_${now.year}_${now.month}';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null || cachedJson.isEmpty) {
        debugPrint('[الإشعارات] لا توجد بيانات صلوات في الكاش المحلي بعد لجدولتها.');
        return;
      }

      final list = jsonDecode(cachedJson) as List<dynamic>;
      const prayerNames = {
        'Fajr': 'الفجر',
        'Dhuhr': 'الظهر',
        'Asr': 'العصر',
        'Maghrib': 'المغرب',
        'Isha': 'العشاء',
      };

      int scheduledCount = 0;

      for (final item in list) {
        final dateObj = item['date'] as Map<String, dynamic>?;
        final gregorian = dateObj?['gregorian'] as Map<String, dynamic>?;
        final dayNum = int.tryParse(gregorian?['day']?.toString() ?? '');
        final monthNum =
            int.tryParse(gregorian?['month']?['number']?.toString() ?? '');
        final yearNum = int.tryParse(gregorian?['year']?.toString() ?? '');

        if (dayNum == null || monthNum == null || yearNum == null) continue;

        // فقط الأيام القادمة ضمن النطاق المحدد
        if (dayNum < now.day || dayNum > now.day + daysAhead) continue;

        final timings = item['timings'] as Map<String, dynamic>?;
        if (timings == null) continue;

        int prayerIdx = 0;
        for (final entry in prayerNames.entries) {
          prayerIdx++;
          final rawTime = timings[entry.key];
          if (rawTime == null) continue;

          final clean = rawTime.toString().split('(').first.trim();
          final parts = clean.split(':');
          if (parts.length < 2) continue;

          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          final scheduledDate =
              DateTime(yearNum, monthNum, dayNum, hour, minute);

          if (scheduledDate.isAfter(now)) {
            // معرف فريد للصلوات يبدأ من 500000 لتجنب التضارب مع مهام المستخدم
            final int notificationId = 500000 + (dayNum * 10) + prayerIdx;

            await schedulePrayerNotification(
              id: notificationId,
              prayerName: entry.value,
              scheduledTime: scheduledDate,
              title: 'موعد أذان ${entry.value}',
              customBody:
                  'حان الآن موعد أذان صلاة ${entry.value} حسب التوقيت المحلي',
            );
            scheduledCount++;
          }
        }
      }

      debugPrint(
          '[الإشعارات] تم بنجاح جدولة $scheduledCount إشعاراً لمواقيت الصلوات القادمة.');
    } catch (e) {
      debugPrint('[الإشعارات] خطأ أثناء جدولة إشعارات الصلوات من الكاش: $e');
    }
  }

  /// جدولة تنبيه أذان صلاة محددة بإعدادات فائقة الأولوية لاختراق الصامت وإيقاظ الشاشة
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    String? title,
    String? customBody,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledTime, tz.local);
    final String notifTitle = title ?? 'موعد أذان $prayerName';
    final String notifBody = customBody ??
        'حان الآن موعد أذان صلاة $prayerName حسب التوقيت المحلي';

    const AndroidNotificationDetails prayerAndroidDetails =
        AndroidNotificationDetails(
      'prayer_channel_v2',
      'تنبيهات أذان الصلاة',
      channelDescription:
          'إشعارات ومنبهات مواقيت الصلاة ذات الأولوية القصوى التي تخترق الصامت',
      importance: Importance.max,
      priority: Priority.high,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: prayerAndroidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: notifTitle,
        body: notifBody,
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
          '[الإشعارات] تمت جدولة تنبيه أذان $prayerName برقم ($id) في: $scheduledTime');
    } catch (exactError) {
      debugPrint(
          '[الإشعارات] تعذر الجدولة الدقيقة لتنبيه الأذان ($exactError)، التبديل للوضع البديل.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: notifTitle,
          body: notifBody,
          scheduledDate: tzDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (fallbackError) {
        debugPrint(
            '[الإشعارات] فشلت جدولة تنبيه الأذان نهائياً: $fallbackError');
      }
    }
  }

  /// معرّفات التذكيرات الروحانية
  static const int idMorningAzkar = 1001;
  static const int idEveningAzkar = 1002;
  static const int idFridaySunan = 1003;
  static const int idQuranPortion = 1004;

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfFridayAtTime(int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != DateTime.friday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// جدولة التذكيرات الروحانية بناءً على إعدادات المستخدم المحفوظة في SharedPreferences
  Future<void> scheduleSpiritualReminders() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final bool azkarEnabled = prefs.getBool('reminder_azkar_enabled') ?? true;
    final bool fridayEnabled =
        prefs.getBool('reminder_friday_sunan_enabled') ?? true;
    final bool quranPortionEnabled =
        prefs.getBool('reminder_quran_portion_enabled') ?? true;
    final int quranHour = prefs.getInt('reminder_quran_portion_hour') ?? 20;
    final int quranMinute = prefs.getInt('reminder_quran_portion_minute') ?? 0;

    const AndroidNotificationDetails spiritualAndroidDetails =
        AndroidNotificationDetails(
      'spiritual_reminders_channel',
      'التذكيرات الروحانية',
      channelDescription:
          'تنبيهات أذكار الصباح والمساء والورد القرآني وسنن يوم الجمعة',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails spiritualIosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails spiritualDetails = NotificationDetails(
      android: spiritualAndroidDetails,
      iOS: spiritualIosDetails,
    );

    // 1. أذكار الصباح والمساء
    if (azkarEnabled) {
      // أذكار الصباح في الساعة 7:00 صباحاً يومياً
      final tzMorning = _nextInstanceOfTime(7, 0);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: idMorningAzkar,
          title: 'أذكار الصباح',
          body: 'ألا بذكر الله تطمئن القلوب',
          scheduledDate: tzMorning,
          notificationDetails: spiritualDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('[التذكيرات] تمت جدولة أذكار الصباح يومياً في 7:00 ص');
      } catch (e) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: idMorningAzkar,
            title: 'أذكار الصباح',
            body: 'ألا بذكر الله تطمئن القلوب',
            scheduledDate: tzMorning,
            notificationDetails: spiritualDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (_) {}
      }

      // أذكار المساء في الساعة 5:00 مساءً (17:00) يومياً
      final tzEvening = _nextInstanceOfTime(17, 0);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: idEveningAzkar,
          title: 'أذكار المساء',
          body: 'ألا بذكر الله تطمئن القلوب',
          scheduledDate: tzEvening,
          notificationDetails: spiritualDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('[التذكيرات] تمت جدولة أذكار المساء يومياً في 5:00 م');
      } catch (e) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: idEveningAzkar,
            title: 'أذكار المساء',
            body: 'ألا بذكر الله تطمئن القلوب',
            scheduledDate: tzEvening,
            notificationDetails: spiritualDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (_) {}
      }
    } else {
      await cancelNotification(idMorningAzkar);
      await cancelNotification(idEveningAzkar);
      debugPrint('[التذكيرات] تم إلغاء تذكيرات أذكار الصباح والمساء');
    }

    // 2. سنن يوم الجمعة (سورة الكهف) أسبوعياً في الساعة 9:00 صباحاً
    if (fridayEnabled) {
      final tzFriday = _nextInstanceOfFridayAtTime(9, 0);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: idFridaySunan,
          title: 'سنن الجمعة',
          body: 'لا تنس قراءة سورة الكهف والصلاة على النبي ﷺ',
          scheduledDate: tzFriday,
          notificationDetails: spiritualDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        debugPrint('[التذكيرات] تمت جدولة تذكير سنن الجمعة أسبوعياً في 9:00 ص');
      } catch (e) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: idFridaySunan,
            title: 'سنن الجمعة',
            body: 'لا تنس قراءة سورة الكهف والصلاة على النبي ﷺ',
            scheduledDate: tzFriday,
            notificationDetails: spiritualDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } catch (_) {}
      }
    } else {
      await cancelNotification(idFridaySunan);
      debugPrint('[التذكيرات] تم إلغاء تذكير سنن الجمعة');
    }

    // 3. الورد القرآني في الوقت المحدد من المستخدم يومياً
    if (quranPortionEnabled) {
      final tzQuran = _nextInstanceOfTime(quranHour, quranMinute);
      try {
        await _notificationsPlugin.zonedSchedule(
          id: idQuranPortion,
          title: 'وردك من القرآن',
          body: 'قليلك الدائم خير من الكثير المنقطع',
          scheduledDate: tzQuran,
          notificationDetails: spiritualDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
            '[التذكيرات] تمت جدولة تذكير الورد القرآني يومياً في $quranHour:$quranMinute');
      } catch (e) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: idQuranPortion,
            title: 'وردك من القرآن',
            body: 'قليلك الدائم خير من الكثير المنقطع',
            scheduledDate: tzQuran,
            notificationDetails: spiritualDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (_) {}
      }
    } else {
      await cancelNotification(idQuranPortion);
      debugPrint('[التذكيرات] تم إلغاء تذكير الورد القرآني');
    }
  }
}
