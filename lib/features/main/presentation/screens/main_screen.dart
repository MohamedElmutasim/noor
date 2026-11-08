import 'package:flutter/material.dart';
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/constants/app_strings.dart';
import 'package:noor/features/azkar/presentation/screens/azkar_screen.dart';
import 'package:noor/features/azkar/presentation/screens/sebha_screen.dart';
import 'package:noor/features/home/presentation/screens/home_screen.dart';
import 'package:noor/features/khatmah/presentation/screens/khatmah_screen.dart';
import 'package:noor/features/quran/presentation/screens/quran_screen.dart';
import 'package:noor/features/settings/presentation/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    QuranScreen(),
    KhatmahScreen(),
    AzkarScreen(),
    SebhaScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories_rounded),
              label: AppStrings.navQuran,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: AppStrings.navKhatmah,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.brightness_medium_outlined),
              activeIcon: Icon(Icons.brightness_medium_rounded),
              label: AppStrings.navAzkar,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.touch_app_outlined),
              activeIcon: Icon(Icons.touch_app_rounded),
              label: AppStrings.navSebha,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
