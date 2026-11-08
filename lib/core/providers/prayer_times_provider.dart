import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/prayer_times_service.dart';
import '../services/widget_service.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final PrayerTimesService _service = PrayerTimesService();

  late NextPrayerInfo _nextPrayer;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isLoading = false;
  bool _isOnline = true;

  PrayerTimesProvider() {
    // 1. حساب موعد الصلاة القادمة فوراً من الكاش المحلي (Offline-First دون أي تأخير)
    _nextPrayer = _service.getNextPrayer();
    _syncWidget();
    _startTimer();
    _initConnectivityListener();
    _initializeData();
  }

  NextPrayerInfo get nextPrayer => _nextPrayer;
  String get locationName => _service.locationName;
  String get cityName => _service.cityName;
  String get countryName => _service.countryName;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  HijriDateInfo get hijriDate => _service.todayHijriDate;
  String get fullHijriDate => _service.todayHijriDate.fullDate;
  List<String> get holidays => _service.todayHijriDate.holidays;

  String _formatTime(DateTime time) {
    final int hour24 = time.hour;
    final int hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final String period = hour24 >= 12 ? 'م' : 'ص';
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  void _syncWidget() {
    unawaited(
      WidgetService.updatePrayerWidget(
        _nextPrayer.name,
        _formatTime(_nextPrayer.time),
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _nextPrayer = _service.getNextPrayer();
      _syncWidget();
      notifyListeners();
    });
  }

  /// مراقبة حالة الاتصال بالإنترنت ومزامنة البيانات فور عودة الشبكة
  void _initConnectivityListener() {
    try {
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final bool hasConnection =
            results.any((result) => result != ConnectivityResult.none);

        final bool wasOffline = !_isOnline;
        _isOnline = hasConnection;

        if (hasConnection && wasOffline) {
          debugPrint(
              '[مواقيت الصلاة] تم رصد عودة الاتصال بالإنترنت، بدء تحديث المواقيت والكاش تلقائياً...');
          syncWithApiAndRefresh();
        }
      });
    } catch (e) {
      debugPrint('[مواقيت الصلاة] تعذر بدء مراقبة الاتصال: $e');
    }
  }

  /// القراءة الفورية من الكاش المحلي ثم محاولة الجلب الصامت في الخلفية
  Future<void> _initializeData() async {
    // 1. استرجاع بيانات الكاش الفوري دون تأخير (Offline-First)
    await _service.initializeAndCacheCalendar();
    _nextPrayer = _service.getNextPrayer();
    _syncWidget();
    notifyListeners();

    // 2. تحديث الموقع ومزامنة البيانات في الخلفية
    await updateLocationAndPrayers();
  }

  /// جلب البيانات من Aladhan API وتحديث الكاش والواجهة بصمت
  Future<void> syncWithApiAndRefresh() async {
    try {
      await _service.syncCalendarSilently();
      _nextPrayer = _service.getNextPrayer();
      _syncWidget();
      notifyListeners();
      unawaited(NotificationService().scheduleUpcomingPrayerNotifications());
    } catch (e) {
      debugPrint('[مواقيت الصلاة] خطأ أثناء المزامنة مع الـ API: $e');
    }
  }

  /// طلب صلاحية الموقع وتحديث الإحداثيات والتقويم وجدولة أذان الصلوات
  Future<void> updateLocationAndPrayers() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.requestLocationPermission();
      await _service.updateUserLocation();
      await _service.initializeAndCacheCalendar();
      _nextPrayer = _service.getNextPrayer();
      _syncWidget();
    } catch (e) {
      debugPrint('[مواقيت الصلاة] خطأ أثناء تحديث الموقع والمواقيت: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // جدولة إشعارات الأذان للأيام القادمة استناداً إلى بيانات الكاش
    unawaited(NotificationService().scheduleUpcomingPrayerNotifications());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
