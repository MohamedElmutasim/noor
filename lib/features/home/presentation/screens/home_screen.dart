import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/constants/app_strings.dart';
import 'package:noor/core/constants/asma_al_husna.dart';
import 'package:noor/core/providers/khatmah_provider.dart';
import 'package:noor/core/providers/prayer_times_provider.dart';
import 'package:noor/features/khatmah/presentation/screens/khatmah_screen.dart';
import 'package:noor/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:noor/features/ramadan/presentation/screens/ramadan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PrayerTimesProvider>().updateLocationAndPrayers();
      }
    });
  }

  String _formatTime(DateTime time) {
    final int hour24 = time.hour;
    final int hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final String period = hour24 >= 12 ? 'م' : 'ص';
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  String _formatRemainingDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else if (hours > 0) {
      return '$hours ساعة';
    } else if (minutes > 0) {
      return '$minutes دقيقة';
    } else {
      return 'أقل من دقيقة';
    }
  }

  void _showAllNamesBottomSheet(BuildContext context, int todayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          height: MediaQuery.of(bottomSheetContext).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أسماء الله الحسنى (99 اسماً)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.divider, height: 1),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: AsmaAlHusna.names.length,
                    itemBuilder: (context, index) {
                      final isToday = index + 1 == todayIndex;
                      return Container(
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AsmaAlHusna.names[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isToday ? AppColors.white : AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                color: isToday
                                    ? AppColors.white.withValues(alpha: 0.8)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHijriDetailsBottomSheet(BuildContext context, PrayerTimesProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'التاريخ الهجري والمناسبات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    provider.fullHijriDate,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الموقع الحالي: ${provider.locationName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (provider.holidays.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFF57F17),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'نفحات اليوم: ${provider.holidays.join('، ')}',
                              style: GoogleFonts.amiri(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.0),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor ?? AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 8,
                        color: badgeTextColor ?? AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesProvider = context.watch<PrayerTimesProvider>();
    final khatmahProvider = context.watch<KhatmahProvider>();
    final nextPrayer = prayerTimesProvider.nextPrayer;
    final todayNameData = AsmaAlHusna.getTodayName();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 24),
          children: [
            // 1. بطاقة التحية والتاريخ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      AppStrings.homeGreeting,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. بطاقة موعد الصلاة القادمة والوقت المتبقي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                ),
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.access_time_filled_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  nextPrayer.name,
                                  style: GoogleFonts.amiri(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    height: 1.1,
                                  ),
                                ),
                                // شارة اسم المدينة والدولة
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        prayerTimesProvider.locationName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'الموعد: ${_formatTime(nextPrayer.time)} (متبقي ${_formatRemainingDuration(nextPrayer.remaining)})',
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
              ),
            ),

            // 3. بانر أسماء الله الحسنى اليومي (مباشرة أسفل موعد الصلاة بتصميمه المستطيل)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showAllNamesBottomSheet(context, todayNameData.index),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryDark, width: 1.2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/islamic_bg.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryDark.withValues(alpha: 0.90),
                            AppColors.primary.withValues(alpha: 0.78),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 13,
                                      color: AppColors.white,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'اسم اليوم',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'الاسم ${todayNameData.index} من 99',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: AppColors.white.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            todayNameData.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 4. شبكة المربعات المتجاورة (عنصرين في كل صف عبر GridView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  // المربع الأول: التقويم الهجري والمناسبات
                  _buildGridShortcutCard(
                    icon: Icons.calendar_month_rounded,
                    title: prayerTimesProvider.hijriDate.day.isNotEmpty
                        ? '${prayerTimesProvider.hijriDate.day} ${prayerTimesProvider.hijriDate.monthName}'
                        : 'التقويم الهجري',
                    subtitle: prayerTimesProvider.holidays.isNotEmpty
                        ? prayerTimesProvider.holidays.first
                        : '${prayerTimesProvider.hijriDate.year} هـ',
                    badgeColor: prayerTimesProvider.holidays.isNotEmpty
                        ? const Color(0xFFFFF8E1)
                        : null,
                    badgeTextColor: prayerTimesProvider.holidays.isNotEmpty
                        ? const Color(0xFFE65100)
                        : null,
                    onTap: () => _showHijriDetailsBottomSheet(context, prayerTimesProvider),
                  ),

                  // المربع الثاني: اتجاه القبلة المشرفة
                  _buildGridShortcutCard(
                    icon: Icons.explore_rounded,
                    title: 'اتجاه القبلة',
                    subtitle: 'بوصلة الكعبة',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const QiblaScreen(),
                        ),
                      );
                    },
                  ),

                  // المربع الثالث: إمساكية شهر رمضان المبارك
                  _buildGridShortcutCard(
                    icon: Icons.nightlight_round,
                    title: 'إمساكية رمضان',
                    subtitle: 'مواقيت الشهر',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RamadanScreen(),
                        ),
                      );
                    },
                  ),

                  // المربع الرابع: الختمة القرآنية
                  _buildGridShortcutCard(
                    icon: Icons.menu_book_rounded,
                    title: 'الختمة القرآنية',
                    subtitle: 'إنجاز ${khatmahProvider.progressPercentage}%',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KhatmahScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
