import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/bookmark_provider.dart';
import 'core/providers/khatmah_provider.dart';
import 'core/providers/notifications_provider.dart';
import 'core/providers/prayer_times_provider.dart';
import 'core/services/background_task_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/prayer_times_service.dart';
import 'core/services/widget_service.dart';
import 'core/theme/app_theme.dart';
import 'features/main/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await WidgetService.updateAsmaAlHusnaWidget();
  await BackgroundTaskService().initialize();
  runApp(const NoorApp());
}

class NoorApp extends StatefulWidget {
  const NoorApp({super.key});

  @override
  State<NoorApp> createState() => _NoorAppState();
}

class _NoorAppState extends State<NoorApp> {
  @override
  void initState() {
    super.initState();
    // طلب الصلاحيات فور بناء الإطار الأول لضمان ظهور نوافذ الأذونات للمستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. طلب صلاحيات الإشعارات والمنبهات الدقيقة
      await NotificationService().requestPermissions();
      // 2. جدولة التذكيرات الروحانية (الصباح والمساء، الجمعة، الورد القرآني)
      await NotificationService().scheduleSpiritualReminders();
      // 3. طلب صلاحية الموقع الجغرافي صراحة
      await PrayerTimesService().requestLocationPermission();
      // 4. تحديث الإحداثيات ومواقيت الصلاة ومزامنة التقويم الشهري في الخلفية
      await PrayerTimesService().updateUserLocation();
      await PrayerTimesService().initializeAndCacheCalendar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => PrayerTimesProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => KhatmahProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainScreen(),
      ),
    );
  }
}
