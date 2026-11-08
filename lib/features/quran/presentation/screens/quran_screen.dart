import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/constants/app_strings.dart';
import 'package:noor/core/providers/bookmark_provider.dart';
import 'package:noor/features/quran_audio/presentation/screens/audio_player_screen.dart';
import 'package:noor/features/quran_audio/presentation/screens/audio_surah_list_screen.dart';
import 'mushaf_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPlaceArabic(String place) {
    if (place.toLowerCase() == 'makkah') {
      return 'مكية';
    } else {
      return 'مدنية';
    }
  }

  List<int> _getFilteredSurahs() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return List<int>.generate(quran.totalSurahCount, (i) => i + 1);
    }

    return List<int>.generate(quran.totalSurahCount, (i) => i + 1).where((surahNumber) {
      final nameArabic = quran.getSurahNameArabic(surahNumber).toLowerCase();
      final nameEnglish = quran.getSurahNameEnglish(surahNumber).toLowerCase();
      final numberStr = surahNumber.toString();

      return nameArabic.contains(query) ||
          nameEnglish.contains(query) ||
          numberStr == query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final int savedPage = bookmarkProvider.savedPage;

    // استخراج اسم السورة في الصفحة المحفوظة
    String savedSurahName = 'الفاتحة';
    try {
      final pageData = quran.getPageData(savedPage);
      if (pageData.isNotEmpty) {
        final int surahId = pageData.first['surah'] as int;
        savedSurahName = quran.getSurahNameArabic(surahId);
      }
    } catch (_) {}

    final filteredSurahs = _getFilteredSurahs();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          AppStrings.quranTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headphones_rounded, color: AppColors.primary),
            tooltip: 'تلاوات القرآن الكريم',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AudioSurahListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // بطاقة متابعة القراءة
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              color: AppColors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MushafScreen(initialPage: savedPage),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
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
                              'متابعة القراءة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الصفحة $savedPage • سورة $savedSurahName',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'فتح',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // بطاقة الانتقال إلى قسم التلاوات والاستماع
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 4.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              color: AppColors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AudioSurahListScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تلاوات القرآن الكريم',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'استماع وتنزيل السور بصوت الشيخ مشاري العفاسي',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'استماع',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.primaryDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // شريط البحث لتصفية السور
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم السورة أو رقمها...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // قائمة السور
          Expanded(
            child: filteredSurahs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'لا توجد سورة بهذا الاسم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'تأكد من كتابة اسم السورة أو رقمها بشكل صحيح',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final int surahNumber = filteredSurahs[index];
                      final String surahNameArabic = quran.getSurahNameArabic(surahNumber);
                      final int verseCount = quran.getVerseCount(surahNumber);
                      final String place = _getPlaceArabic(quran.getPlaceOfRevelation(surahNumber));

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border, width: 1.2),
                        ),
                        elevation: 0,
                        color: AppColors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$surahNumber',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            'سورة $surahNameArabic',
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    place,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$verseCount آية',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.headphones_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                tooltip: 'استماع للسورة',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AudioPlayerScreen(surahNumber: surahNumber),
                                    ),
                                  );
                                },
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          onTap: () {
                            // الانتقال المباشر لصفحة بداية هذه السورة في المصحف
                            final int startPage = quran.getPageNumber(surahNumber, 1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MushafScreen(initialPage: startPage),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
