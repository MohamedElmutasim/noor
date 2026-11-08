import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noor/core/constants/app_colors.dart';

class SebhaScreen extends StatefulWidget {
  const SebhaScreen({super.key});

  @override
  State<SebhaScreen> createState() => _SebhaScreenState();
}

class _SebhaScreenState extends State<SebhaScreen>
    with SingleTickerProviderStateMixin {
  static const String _prefTotalKey = 'total_tasbeeh_count';

  final List<String> _tasbeehList = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ',
  ];

  int _selectedTasbeehIndex = 0;
  int _currentCount = 0;
  int _totalCount = 0;
  final int _targetCycle = 33;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadTotalCount();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCount = prefs.getInt(_prefTotalKey) ?? 0;
    });
  }

  Future<void> _incrementCount() async {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      _animationController.forward();
    });

    setState(() {
      _currentCount++;
      _totalCount++;
    });

    if (_currentCount % _targetCycle == 0) {
      HapticFeedback.mediumImpact();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTotalKey, _totalCount);
  }

  void _resetCurrentCount() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentCount = 0;
    });
  }

  Future<void> _resetTotalCountDialog() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تصفير إجمالي التسبيحات',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'هل ترغب في إعادة ضبط إجمالي التسبيحات التراكمي إلى الصفر؟',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('تصفير الإجمالي'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefTotalKey, 0);
      setState(() {
        _totalCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycleProgress = (_currentCount % _targetCycle) / _targetCycle;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('السبحة الإلكترونية'),
        actions: [
          IconButton(
            tooltip: 'تصفير إجمالي التسبيحات التراكمي',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _resetTotalCountDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // بطاقة الإنجاز التراكمي (إجمالي التسبيحات)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إجمالي التسبيحات التراكمي',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_totalCount تسبيحة',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // قائمة اختيار صيغة التسبيح الحالية
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tasbeehList.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedTasbeehIndex == index;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        _tasbeehList[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTasbeehIndex = index;
                            _currentCount = 0;
                          });
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // بطاقة عرض الذكر الحالي والعداد
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Column(
                  children: [
                    // نص التسبيحة الحالية
                    Text(
                      _tasbeehList[_selectedTasbeehIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // العداد الرقمي الحالي
                    Text(
                      '$_currentCount',
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'دورة $_targetCycle تسبيحة (المكتمل منها: ${_currentCount ~/ _targetCycle})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // شريط التقدم للدورة الحالية (33 تسبيحة)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: cycleProgress == 0 && _currentCount > 0
                            ? 1.0
                            : cycleProgress,
                        minHeight: 6,
                        backgroundColor: AppColors.primaryLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // زر التسبيح الدائري الكبير في المنتصف
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(110),
                    onTap: _incrementCount,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: AppColors.lightGreen,
                          width: 8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 46,
                            color: AppColors.white,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'اضغط للتسبيح',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // زر صغير لتصفير العداد الحالي (Reset)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _resetCurrentCount,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'تصفير العداد الحالي',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.border,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
