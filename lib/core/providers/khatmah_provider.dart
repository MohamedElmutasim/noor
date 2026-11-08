import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KhatmahProvider extends ChangeNotifier {
  static const String _khatmahPageKey = 'khatmah_current_page';
  static const String _khatmahTargetDaysKey = 'khatmah_target_days';
  static const String _khatmahLastDateKey = 'khatmah_last_read_date';

  static const int totalPages = 604;

  int _currentPage = 1;
  int _targetDays = 30;
  DateTime? _lastReadDate;
  bool _isLoading = true;

  KhatmahProvider() {
    _loadState();
  }

  int get currentPage => _currentPage;
  int get targetDays => _targetDays;
  DateTime? get lastReadDate => _lastReadDate;
  bool get isLoading => _isLoading;

  /// عدد الصفحات المنجزة والمكتملة فعلياً (إذا كانت الصفحة الحالية 1 فالإنجاز هو 0 صفحة)
  int get completedPages => (_currentPage - 1).clamp(0, totalPages);

  /// نسبة الإنجاز المئوية (قيمة عشرية من 0.0 إلى 1.0)
  /// المعادلة: progress = (currentPage - 1) / 604
  double get progress => (completedPages / totalPages).clamp(0.0, 1.0);

  /// نسبة الإنجاز كعدد صحيح (0 إلى 100)
  int get progressPercentage => ((completedPages / totalPages) * 100).toInt().clamp(0, 100);

  /// الصفحات المتبقية لإتمام الختمة
  int get remainingPages => (totalPages - completedPages).clamp(0, totalPages);

  /// هل اكتملت الختمة
  bool get isCompleted => completedPages >= totalPages;

  /// متوسط عدد الصفحات اليومية المقترحة لإتمام الختمة خلال الفترة المحددة
  int get dailyPagesTarget => (_targetDays > 0) ? (totalPages / _targetDays).ceil() : 20;

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentPage = prefs.getInt(_khatmahPageKey) ?? 1;
      _targetDays = prefs.getInt(_khatmahTargetDaysKey) ?? 30;
      final String? dateStr = prefs.getString(_khatmahLastDateKey);
      if (dateStr != null) {
        _lastReadDate = DateTime.tryParse(dateStr);
      }
    } catch (e) {
      debugPrint('[KhatmahProvider] خطأ أثناء استعادة بيانات الختمة: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث الصفحة الحالية للختمة وحفظها في التخزين المحلي
  Future<void> updatePage(int page) async {
    final int clampedPage = page.clamp(1, totalPages);
    if (_currentPage == clampedPage) return;

    _currentPage = clampedPage;
    _lastReadDate = DateTime.now();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_khatmahPageKey, clampedPage);
      await prefs.setString(_khatmahLastDateKey, _lastReadDate!.toIso8601String());
    } catch (e) {
      debugPrint('[KhatmahProvider] خطأ أثناء حفظ صفحة الختمة: $e');
    }
  }

  /// إعادة ضبط الختمة للبدء من الصفحة الأولى من جديد
  Future<void> resetKhatmah() async {
    _currentPage = 1;
    _lastReadDate = DateTime.now();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_khatmahPageKey, 1);
      await prefs.setString(_khatmahLastDateKey, _lastReadDate!.toIso8601String());
    } catch (e) {
      debugPrint('[KhatmahProvider] خطأ أثناء إعادة ضبط الختمة: $e');
    }
  }

  /// دالة لبدء ختمة جديدة (مرادفة لإعادة الضبط للصفحة الأولى)
  Future<void> startNewKhatmah() => resetKhatmah();

  /// تعيين عدد الأيام المستهدفة لختم المصحف
  Future<void> setTargetDays(int days) async {
    if (days <= 0) return;
    _targetDays = days;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_khatmahTargetDaysKey, days);
    } catch (e) {
      debugPrint('[KhatmahProvider] خطأ أثناء حفظ الأيام المستهدفة: $e');
    }
  }
}
