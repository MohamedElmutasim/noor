import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/services/prayer_times_service.dart';
import 'package:noor/core/services/qibla_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final QiblaService _qiblaService = QiblaService();

  bool _isLoading = true;
  String? _errorMessage;
  double? _qiblaDirection; // زاوية القبلة بالدرجات من الشمال
  double? _deviceHeading; // زاوية اتجاه الهاتف الحالي

  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _isAligned = false;
  bool _hasVibrated = false;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final direction = await _qiblaService.fetchQiblaDirection();
      if (mounted) {
        setState(() {
          _qiblaDirection = direction;
          _isLoading = false;
        });
        _startListeningToCompass();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'تعذر جلب زاوية القبلة، يرجى التأكد من اتصال الإنترنت ثم إعادة المحاولة';
        });
      }
    }
  }

  void _startListeningToCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() {
        _errorMessage = 'مستشعر البوصلة غير متوفر في هذا الجهاز';
      });
      return;
    }

    _compassSubscription = stream.listen((CompassEvent event) {
      if (!mounted) return;
      final heading = event.heading;
      if (heading == null) return;

      setState(() {
        _deviceHeading = heading;
      });

      _checkAlignment(heading);
    });
  }

  void _checkAlignment(double heading) {
    if (_qiblaDirection == null) return;

    double diff = (heading - _qiblaDirection!).abs() % 360;
    if (diff > 180) {
      diff = 360 - diff;
    }

    final bool currentlyAligned = diff <= 4.0;

    if (currentlyAligned != _isAligned) {
      setState(() {
        _isAligned = currentlyAligned;
      });

      if (currentlyAligned && !_hasVibrated) {
        _hasVibrated = true;
        _triggerVibration();
      }
    }

    if (diff > 6.0) {
      _hasVibrated = false;
    }
  }

  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 80);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationName = PrayerTimesService().locationName;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'جاري تحديد زاوية القبلة بدقة...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.explore_off_rounded,
                              size: 44,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _initQibla,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // بطاقة الموقع والزاوية الحسابية
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locationName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'زاوية القبلة: ${_qiblaDirection?.toStringAsFixed(1) ?? "--"}° من الشمال',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // شارة حالة الاتجاه
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isAligned
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            boxShadow: _isAligned
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAligned
                                    ? Icons.check_circle_rounded
                                    : Icons.screen_rotation_rounded,
                                size: 18,
                                color: _isAligned
                                    ? AppColors.white
                                    : AppColors.primaryDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAligned
                                    ? 'أنت الآن باتجاه القبلة المشرفة'
                                    : 'أدر الهاتف لمطابقة زاوية القبلة',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isAligned
                                      ? AppColors.white
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // رسم البوصلة الهندسية التفاعلية
                        _buildCompass(),

                        const SizedBox(height: 32),

                        // قراءات الدرجات التوجيهية
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'اتجاه الهاتف',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_deviceHeading?.toStringAsFixed(0) ?? "0"}°',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.divider,
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'القبلة المشرفة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_qiblaDirection?.toStringAsFixed(0) ?? "0"}°',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'تأكد من وضع الهاتف أفقياً بعيداً عن أي مجالات مغناطيسية أو معادن للحصول على أدق قراءة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCompass() {
    final double heading = _deviceHeading ?? 0.0;
    final double qibla = _qiblaDirection ?? 0.0;

    // زاوية تدوير البوصلة بحيث يعبر الشمال عن الاتجاه الحقيقي
    final double compassAngle = (heading * (math.pi / 180) * -1);

    // زاوية مؤشر القبلة بالنسبة للبوصلة
    final double qiblaNeedleAngle =
        ((qibla - heading) * (math.pi / 180));

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // قرص البوصلة الخلفي الدوار
          Transform.rotate(
            angle: compassAngle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                border: Border.all(
                  color: _isAligned ? AppColors.primary : AppColors.border,
                  width: _isAligned ? 3.5 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isAligned
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CompassDialPainter(isAligned: _isAligned),
              ),
            ),
          ),

          // مؤشر القبلة المشرفة (سهم يتجه نحو الكعبة الشريفة)
          Transform.rotate(
            angle: qiblaNeedleAngle,
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // السهم المشير للقبلة
                  Positioned(
                    top: 14,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _isAligned
                                ? AppColors.primary
                                : AppColors.primaryDark,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'القبلة',
                          style: GoogleFonts.amiri(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isAligned
                                ? AppColors.primary
                                : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // نقطة المركز الثابتة
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAligned ? AppColors.primary : AppColors.primaryDark,
              border: Border.all(color: AppColors.white, width: 3),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final bool isAligned;

  _CompassDialPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintLine = Paint()
      ..color = isAligned ? AppColors.primary : AppColors.border
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final paintNorth = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // رسم علامات الدرجات
    for (int i = 0; i < 360; i += 15) {
      final double angle = i * (math.pi / 180);
      final bool isMajor = (i % 90 == 0);
      final double tickLength = isMajor ? 14.0 : 7.0;

      final startX = center.dx + (radius - 10) * math.cos(angle);
      final startY = center.dy + (radius - 10) * math.sin(angle);
      final endX = center.dx + (radius - 10 - tickLength) * math.cos(angle);
      final endY = center.dy + (radius - 10 - tickLength) * math.sin(angle);

      final isN = (i == 270); // 270 rad on standard canvas corresponds to top
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        isN ? paintNorth : paintLine,
      );
    }

    // كتابة الأحرف الأساسية (ش، ج، ق، غ)
    const textStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    const northStyle = TextStyle(
      color: Colors.redAccent,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    _drawText(canvas, 'ش', Offset(center.dx, 22), northStyle);
    _drawText(canvas, 'ج', Offset(center.dx, size.height - 22), textStyle);
    _drawText(canvas, 'ق', Offset(size.width - 22, center.dy), textStyle);
    _drawText(canvas, 'غ', Offset(22, center.dy), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.rtl,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
