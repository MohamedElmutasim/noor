import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/services/prayer_times_service.dart';
import 'package:noor/core/services/ramadan_api_service.dart';

class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  late Future<List<RamadanDayInfo>> _ramadanFuture;
  late final int _currentHijriYear;
  int? _currentRamadanDay;

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('ar');
    final hijriNow = HijriCalendar.now();
    _currentHijriYear =
        hijriNow.hMonth > 9 ? hijriNow.hYear + 1 : hijriNow.hYear;

    if (hijriNow.hMonth == 9) {
      _currentRamadanDay = hijriNow.hDay;
    }

    _loadCalendar();
  }

  void _loadCalendar() {
    setState(() {
      _ramadanFuture = RamadanApiService().fetchRamadanCalendar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationName = PrayerTimesService().locationName;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'إمساكية رمضان',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // بطاقة الترويسة المزخرفة
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إمساكية شهر رمضان المبارك',
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'عام $_currentHijriYear هـ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white.withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // محتوى الإمساكية عبر FutureBuilder
          Expanded(
            child: FutureBuilder<List<RamadanDayInfo>>(
              future: _ramadanFuture,
              builder: (context, snapshot) {
                // حالة التحميل
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'جاري جلب إمساكية شهر رمضان المبارك...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // حالة الخطأ أو انقطاع الإنترنت
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'تعذر جلب البيانات',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'يرجى التأكد من الاتصال بالإنترنت لجلب وتحديث إمساكية شهر رمضان بدقة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _loadCalendar,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('إعادة المحاولة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final days = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final dayInfo = days[index];
                    final isToday = _currentRamadanDay == dayInfo.day;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isToday ? AppColors.primary : AppColors.border,
                          width: isToday ? 2.0 : 1.0,
                        ),
                      ),
                      color: AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            // سطر عنوان اليوم
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? AppColors.primary
                                            : AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'اليوم ${dayInfo.day}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isToday
                                              ? AppColors.white
                                              : AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      dayInfo.weekday,
                                      style: GoogleFonts.amiri(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade400),
                                        ),
                                        child: Text(
                                          'اليوم الحالي',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  dayInfo.gregorianDate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(color: AppColors.divider, height: 1),
                            const SizedBox(height: 12),

                            // بطاقات مواقيت الإمساك والإفطار والصلوات
                            Row(
                              children: [
                                // وقت الإمساك
                                Expanded(
                                  child: _buildTimeBox(
                                    title: 'الإمساك',
                                    time: dayInfo.imsak.isNotEmpty
                                        ? dayInfo.imsak
                                        : dayInfo.fajr,
                                    icon: Icons.nightlight_outlined,
                                    highlight: false,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // أذان الفجر
                                Expanded(
                                  child: _buildTimeBox(
                                    title: 'الفجر',
                                    time: dayInfo.fajr,
                                    icon: Icons.wb_twilight_rounded,
                                    highlight: false,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // وقت الإفطار (المغرب)
                                Expanded(
                                  child: _buildTimeBox(
                                    title: 'الإفطار (المغرب)',
                                    time: dayInfo.maghrib,
                                    icon: Icons.wb_sunny_rounded,
                                    highlight: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox({
    required String title,
    required String time,
    required IconData icon,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: highlight ? AppColors.primaryDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: highlight ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
