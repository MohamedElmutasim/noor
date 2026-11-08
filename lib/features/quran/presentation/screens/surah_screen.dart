import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:noor/core/constants/app_colors.dart';

class SurahScreen extends StatelessWidget {
  final int surahNumber;

  const SurahScreen({
    super.key,
    required this.surahNumber,
  });

  String _getPlaceArabic(String place) {
    if (place.toLowerCase() == 'makkah') {
      return 'مكية';
    } else {
      return 'مدنية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahName = quran.getSurahNameArabic(surahNumber);
    final verseCount = quran.getVerseCount(surahNumber);
    final placeOfRevelation = _getPlaceArabic(quran.getPlaceOfRevelation(surahNumber));

    // جمع كافة آيات السورة مع رموز نهاية الآيات القرآنية
    final StringBuffer surahTextBuffer = StringBuffer();
    for (int i = 1; i <= verseCount; i++) {
      final verseText = quran.getVerse(surahNumber, i, verseEndSymbol: true);
      surahTextBuffer.write('$verseText ');
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'سورة $surahName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // بطاقة معلومات السورة
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            elevation: 0,
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'مكان النزول',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        placeOfRevelation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
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
                        'عدد الآيات',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$verseCount آية',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
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
                        'ترتيبها',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'سورة رقم $surahNumber',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // البسملة (لكافة السور باستثناء سورة التوبة)
          if (surahNumber != 9)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Text(
                    quran.basmala,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

          // بطاقة عرض آيات السورة الكريمة
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border, width: 1.2),
            ),
            elevation: 0,
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: SelectableText(
                surahTextBuffer.toString(),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  height: 2.2,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
