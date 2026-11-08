import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  static const String _notificationsKey = 'is_tasks_notifications_enabled';
  final NotificationService _notificationService = NotificationService();

  bool _isNotificationsEnabled = true;
  bool _isLoading = true;

  NotificationsProvider() {
    _loadState();
  }

  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isLoading => _isLoading;

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isNotificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _isNotificationsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);

    if (!value) {
      // إلغاء كافة التنبيهات عند إيقاف ميزة الإشعارات
      await _notificationService.cancelAllNotifications();
    }
  }
}
