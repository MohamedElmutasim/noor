import 'package:home_widget/home_widget.dart';
import 'package:noor/core/constants/asma_al_husna.dart';

class WidgetService {
  WidgetService._();

  static const String androidAsmaWidgetProvider = 'AsmaAlHusnaWidgetProvider';
  static const String iOSAsmaWidgetName = 'AsmaAlHusnaWidget';

  static const String androidPrayerWidgetProvider = 'PrayerTimesWidgetProvider';
  static const String iOSPrayerWidgetName = 'PrayerTimesWidget';

  static const String androidMiniPrayerWidgetProvider = 'MiniPrayerWidgetProvider';
  static const String iOSMiniPrayerWidgetName = 'MiniPrayerWidget';

  /// تحديث بيانات ودجت أسماء الله الحسنى لليوم الحالي
  static Future<void> updateAsmaAlHusnaWidget() async {
    try {
      final todayData = AsmaAlHusna.getTodayName();
      final currentName = todayData.name;
      final currentIndex = todayData.index;

      await HomeWidget.saveWidgetData<String>('daily_name', currentName);
      await HomeWidget.saveWidgetData<String>('daily_index', '$currentIndex');
      await HomeWidget.saveWidgetData<String>(
        'daily_subtitle',
        'الاسم $currentIndex من 99',
      );

      await HomeWidget.updateWidget(
        name: androidAsmaWidgetProvider,
        iOSName: iOSAsmaWidgetName,
      );
    } catch (_) {
      // تفادي إيقاف التطبيق في حال حدوث خطأ غير متوقع أثناء تحديث الودجت
    }
  }

  /// تحديث بيانات ودجت مواقيت الصلاة (الويدجت القياسية والويدجت المصغرة 2x1)
  static Future<void> updatePrayerWidget(
    String prayerName,
    String prayerTime,
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>('prayer_name', prayerName);
      await HomeWidget.saveWidgetData<String>('prayer_time', prayerTime);

      // تحديث الويدجت القياسية لمواقيت الصلاة
      await HomeWidget.updateWidget(
        name: androidPrayerWidgetProvider,
        iOSName: iOSPrayerWidgetName,
      );

      // تحديث الويدجت المصغرة جداً (2x1) لموعد الصلاة القادمة
      await HomeWidget.updateWidget(
        name: androidMiniPrayerWidgetProvider,
        iOSName: iOSMiniPrayerWidgetName,
      );
    } catch (_) {
      // تفادي إيقاف التطبيق في حال حدوث خطأ غير متوقع أثناء تحديث الودجت
    }
  }
}
