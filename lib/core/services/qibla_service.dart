import 'package:dio/dio.dart';
import 'package:noor/core/services/prayer_times_service.dart';

class QiblaService {
  final Dio _dio;
  static double? _cachedDirection;

  QiblaService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
              ),
            );

  static double? get cachedDirection => _cachedDirection;

  /// جلب زاوية اتجاه القبلة بالدرجات بالنسبة للشمال بناءً على الإحداثيات
  Future<double> fetchQiblaDirection({
    double? latitude,
    double? longitude,
  }) async {
    final coords = PrayerTimesService().currentCoordinates;
    final lat = latitude ?? coords.latitude;
    final lng = longitude ?? coords.longitude;

    final url = 'https://api.aladhan.com/v1/qibla/$lat/$lng';

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null && data['direction'] != null) {
          final direction = (data['direction'] as num).toDouble();
          _cachedDirection = direction;
          return direction;
        }
      }
    } catch (_) {
      // في حال وجود قيمة مخزنة مسبقاً، يتم استخدامها كبديل
      if (_cachedDirection != null) {
        return _cachedDirection!;
      }
      rethrow;
    }

    throw Exception('فشل في جلب زاوية القبلة من الخادم');
  }
}
