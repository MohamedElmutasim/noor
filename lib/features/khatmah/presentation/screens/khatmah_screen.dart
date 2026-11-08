import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/constants/app_strings.dart';
import 'package:noor/core/providers/khatmah_provider.dart';
import 'package:noor/features/quran/presentation/screens/mushaf_screen.dart';

class KhatmahScreen extends StatelessWidget {
  const KhatmahScreen({super.key});

  String _getSurahForPage(int page) {
    try {
      final pageData = quran.getPageData(page);
      if (pageData.isNotEmpty) {
        final int surahNum = pageData.first['surah'] as int;
        return 'سورة ${quran.getSurahNameArabic(surahNum)}';
      }
    } catch (_) {}
    return '';
  }

  void _navigateToMushaf(BuildContext context, int targetPage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MushafScreen(
          initialPage: targetPage,
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'بدء ختمة جديدة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في إعادة ضبط الختمة والبدء من الصفحة الأولى؟',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<KhatmahProvider>().resetKhatmah();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'تمت إعادة ضبط الختمة بنجاح، تقبل الله منا ومنكم صالح الأعمال',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final khatmah = context.watch<KhatmahProvider>();

    if (khatmah.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final int currentPage = khatmah.currentPage;
    final String currentSurah = _getSurahForPage(currentPage);
    final int percentage = khatmah.progressPercentage;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.khatmahTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بدء ختمة جديدة',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryDark),
            onPressed: () => _showResetConfirmDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة التقدم الرئيسية
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              elevation: 0,
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'متابعة ختمة المصحف الشريف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentSurah.isNotEmpty ? '$currentSurah (صفحة $currentPage)' : 'صفحة $currentPage',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // شريط التقدم
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: khatmah.progress,
                        minHeight: 12,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // أرقام الإنجاز
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإنجاز: $percentage%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'الصفحة $currentPage من ${KhatmahProvider.totalPages}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // زر مواصلة القراءة
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToMushaf(context, currentPage),
                        icon: const Icon(Icons.auto_stories_rounded, size: 22),
                        label: const Text(
                          'مواصلة القراءة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // بطاقات الإحصائيات السريعة
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                    ),
                    elevation: 0,
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${khatmah.completedPages}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'صفحة منجزة',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                    ),
                    elevation: 0,
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.hourglass_bottom_rounded,
                            color: Colors.amber,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${khatmah.remainingPages}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'صفحة متبقية',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // بطاقة الهدف والورد اليومي
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              elevation: 0,
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الورد اليومي المقترح',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'قراءة حوالي ${khatmah.dailyPagesTarget} صفحة يومياً لإتمام الختمة في ${khatmah.targetDays} يوماً',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
