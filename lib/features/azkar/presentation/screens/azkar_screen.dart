import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/constants/azkar_data.dart';

class AzkarScreen extends StatefulWidget {
  final int initialTabIndex;

  const AzkarScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // تخزين العداد المتبقي لكل ذكر باستخدام معرّف الذكر (id)
  final Map<int, int> _remainingCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _initCounters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initCounters() {
    for (final zekr in AzkarData.morningAzkar) {
      _remainingCounts[zekr.id] = zekr.targetCount;
    }
    for (final zekr in AzkarData.eveningAzkar) {
      _remainingCounts[zekr.id] = zekr.targetCount;
    }
  }

  void _resetCurrentTabCounters(bool isMorning) {
    setState(() {
      final list =
          isMorning ? AzkarData.morningAzkar : AzkarData.eveningAzkar;
      for (final zekr in list) {
        _remainingCounts[zekr.id] = zekr.targetCount;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMorning
              ? 'تمت إعادة ضبط عدادات أذكار الصباح'
              : 'تمت إعادة ضبط عدادات أذكار المساء',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _decrementCount(int id) {
    final current = _remainingCounts[id] ?? 0;
    if (current > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _remainingCounts[id] = current - 1;
      });
    }
  }

  Widget _buildProgressBar(List<ZekrModel> azkarList) {
    final completedCount = azkarList.where((zekr) {
      final remaining = _remainingCounts[zekr.id] ?? zekr.targetCount;
      return remaining == 0;
    }).length;

    final progress =
        azkarList.isEmpty ? 0.0 : completedCount / azkarList.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تمت قراءة $completedCount من ${azkarList.length} أذكار',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAzkarList(List<ZekrModel> azkarList, bool isMorning) {
    return Column(
      children: [
        _buildProgressBar(azkarList),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: azkarList.length,
            itemBuilder: (context, index) {
              final zekr = azkarList[index];
              final remaining = _remainingCounts[zekr.id] ?? zekr.targetCount;
              final isCompleted = remaining == 0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFF0F9F3)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // شريط العنوان والشارة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.primary
                                        : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? AppColors.white
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    zekr.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.primaryLight
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'التكرار: ${zekr.targetCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // نص الذكر
                      Text(
                        zekr.text,
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          height: 2.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // صندوق الفضل والمرجعية
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.menu_book_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                zekr.blessing,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // زر التكرار التفاعلي
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _decrementCount(zekr.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.touch_app_rounded,
                                size: 20,
                                color: isCompleted
                                    ? AppColors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isCompleted
                                    ? 'تم الانتهاء بحمد الله'
                                    : 'المتبقي: $remaining',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? AppColors.white
                                      : AppColors.primaryDark,
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
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('أذكار الصباح والمساء'),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط عدادات الصفحة الحالية',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final isMorning = _tabController.index == 0;
              _resetCurrentTabCounters(isMorning);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.wb_sunny_outlined),
              text: 'أذكار الصباح',
            ),
            Tab(
              icon: Icon(Icons.nightlight_round_outlined),
              text: 'أذكار المساء',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAzkarList(AzkarData.morningAzkar, true),
          _buildAzkarList(AzkarData.eveningAzkar, false),
        ],
      ),
    );
  }
}
