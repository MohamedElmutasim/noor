import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/constants/app_strings.dart';
import 'package:noor/core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // مفاتيح SharedPreferences
  static const String _keyAdhan = 'reminder_adhan_enabled';
  static const String _keyAzkar = 'reminder_azkar_enabled';
  static const String _keyFridaySunan = 'reminder_friday_sunan_enabled';
  static const String _keyQuranPortion = 'reminder_quran_portion_enabled';
  static const String _keyQuranHour = 'reminder_quran_portion_hour';
  static const String _keyQuranMinute = 'reminder_quran_portion_minute';

  bool _adhanEnabled = true;
  bool _azkarEnabled = true;
  bool _fridaySunanEnabled = true;
  bool _quranPortionEnabled = true;
  TimeOfDay _quranPortionTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adhanEnabled = prefs.getBool(_keyAdhan) ?? true;
      _azkarEnabled = prefs.getBool(_keyAzkar) ?? true;
      _fridaySunanEnabled = prefs.getBool(_keyFridaySunan) ?? true;
      _quranPortionEnabled = prefs.getBool(_keyQuranPortion) ?? true;

      final int hour = prefs.getInt(_keyQuranHour) ?? 20;
      final int minute = prefs.getInt(_keyQuranMinute) ?? 0;
      _quranPortionTime = TimeOfDay(hour: hour, minute: minute);
      _isLoading = false;
    });
  }

  Future<void> _updateBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await NotificationService().scheduleSpiritualReminders();
  }

  Future<void> _pickQuranPortionTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _quranPortionTime,
      helpText: AppStrings.selectReminderTime,
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
      builder: (pickerContext, child) {
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _quranPortionTime = picked;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyQuranHour, picked.hour);
      await prefs.setInt(_keyQuranMinute, picked.minute);
      await NotificationService().scheduleSpiritualReminders();
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final int hour24 = time.hour;
    final int hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final String period = hour24 >= 12 ? 'م' : 'ص';
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailingExtra,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      elevation: 0,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: value ? AppColors.primary : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: value ? AppColors.white : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: value,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.lightGreen,
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.border,
                  onChanged: onChanged,
                ),
              ],
            ),
            if (trailingExtra != null) ...[
              const SizedBox(height: 10),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),
              trailingExtra,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                // بطاقة تفعيل صلاحيات الأذان في الخلفية
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                  ),
                  elevation: 0,
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'صلاحيات التنبيه في الخلفية',
                                    style: GoogleFonts.amiri(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'ضرورية لضمان دقة انطلاق الأذان في موعده',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'يتطلب انطلاق الأذان في موعده استثناء التطبيق من قيود توفير طاقة البطارية ومنح إذن المنبهات الدقيقة ليعمل عند إغلاق التطبيق.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await NotificationService().requestBackgroundPrayerPermissions();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'تم طلب صلاحيات العمل بالخلفية وتجاوز قيود البطارية لضمان دقة الأذان',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.notifications_active_rounded, size: 20),
                            label: Text(
                              'تفعيل صلاحيات الأذان في الخلفية',
                              style: GoogleFonts.amiri(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              elevation: 0,
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

                const SizedBox(height: 24),

                // قسم إعدادات التذكيرات الروحانية
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0, right: 4.0),
                  child: Text(
                    AppStrings.remindersSettings,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // 1. تفعيل تنبيهات الأذان
                _buildSwitchCard(
                  icon: Icons.mosque_rounded,
                  title: AppStrings.adhanReminderTitle,
                  subtitle: AppStrings.adhanReminderSubtitle,
                  value: _adhanEnabled,
                  onChanged: (val) {
                    setState(() => _adhanEnabled = val);
                    _updateBoolPref(_keyAdhan, val);
                  },
                ),

                // 2. تذكير أذكار الصباح والمساء
                _buildSwitchCard(
                  icon: Icons.brightness_medium_rounded,
                  title: AppStrings.azkarReminderTitle,
                  subtitle: AppStrings.azkarReminderSubtitle,
                  value: _azkarEnabled,
                  onChanged: (val) {
                    setState(() => _azkarEnabled = val);
                    _updateBoolPref(_keyAzkar, val);
                  },
                ),

                // 3. تذكير سنن يوم الجمعة (سورة الكهف)
                _buildSwitchCard(
                  icon: Icons.calendar_today_rounded,
                  title: AppStrings.fridayReminderTitle,
                  subtitle: AppStrings.fridayReminderSubtitle,
                  value: _fridaySunanEnabled,
                  onChanged: (val) {
                    setState(() => _fridaySunanEnabled = val);
                    _updateBoolPref(_keyFridaySunan, val);
                  },
                ),

                // 4. تذكير الورد القرآني اليومي مع اختيار الوقت
                _buildSwitchCard(
                  icon: Icons.menu_book_rounded,
                  title: AppStrings.quranPortionReminderTitle,
                  subtitle: AppStrings.quranPortionReminderSubtitle,
                  value: _quranPortionEnabled,
                  onChanged: (val) {
                    setState(() => _quranPortionEnabled = val);
                    _updateBoolPref(_keyQuranPortion, val);
                  },
                  trailingExtra: _quranPortionEnabled
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'موعد التذكير بالورد:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _pickQuranPortionTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimeOfDay(_quranPortionTime),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                      color: AppColors.primaryDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),

                const SizedBox(height: 24),

                // قسم عن التطبيق والصدقة الجارية
                const Padding(
                  padding: EdgeInsets.only(bottom: 10.0, right: 4.0),
                  child: Text(
                    AppStrings.aboutApp,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                  ),
                  elevation: 0,
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            AppStrings.appVersion,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            AppStrings.dedicationText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
