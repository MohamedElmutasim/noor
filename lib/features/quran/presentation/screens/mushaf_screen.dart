import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:noor/core/constants/app_colors.dart';
import 'package:noor/core/providers/bookmark_provider.dart';
import 'package:noor/core/providers/khatmah_provider.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;

  const MushafScreen({
    super.key,
    this.initialPage = 1,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, quran.totalPagesCount);
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveCurrentBookmark() {
    final bookmarkProvider = context.read<BookmarkProvider>();
    bookmarkProvider.saveBookmark(_currentPage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ العلامة عند الصفحة $_currentPage بنجاح',
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

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bool isCurrentPageBookmarked = bookmarkProvider.savedPage == _currentPage;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'المصحف الشريف (صفحة $_currentPage)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: isCurrentPageBookmarked ? 'العلامة محفوظة هنا' : 'حفظ العلامة',
            icon: Icon(
              isCurrentPageBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isCurrentPageBookmarked ? AppColors.primary : AppColors.primaryDark,
              size: 26,
            ),
            onPressed: _saveCurrentBookmark,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: quran.totalPagesCount,
        onPageChanged: (pageIndex) {
          final int newPage = pageIndex + 1;
          setState(() {
            _currentPage = newPage;
          });
          context.read<KhatmahProvider>().updatePage(newPage);
        },
        itemBuilder: (context, index) {
          final int pageNumber = index + 1;
          final List pageData = quran.getPageData(pageNumber);

          // استخراج السورة والجزء للصفحة الحالية
          String topSurahName = '';
          int topJuzNumber = 1;

          if (pageData.isNotEmpty) {
            final firstSection = pageData.first;
            final int surahNum = firstSection['surah'] as int;
            final int startVerse = firstSection['start'] as int;
            topSurahName = quran.getSurahNameArabic(surahNum);
            topJuzNumber = quran.getJuzNumber(surahNum, startVerse);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              color: AppColors.white,
              child: Column(
                children: [
                  // الشريط العلوي لمعلومات الصفحة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      border: Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الجزء $topJuzNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'سورة $topSurahName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // جسم الصفحة وعرض الآيات القرآنية
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final section in pageData) ...[
                            // ترويسة السورة والبسملة إذا كانت بداية السورة في هذه الصفحة
                            if (section['start'] == 1) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'سورة ${quran.getSurahNameArabic(section['surah'] as int)}',
                                    style: GoogleFonts.amiri(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // البسملة لجميع السور عدا سورة التوبة وسورة الفاتحة
                              if ((section['surah'] as int) != 9 && (section['surah'] as int) != 1)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Center(
                                    child: Text(
                                      quran.basmala,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.amiri(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],

                            // عرض نصوص آيات هذا المقطع من السورة
                            SelectableText.rich(
                              TextSpan(
                                children: [
                                  for (int v = section['start'] as int;
                                      v <= (section['end'] as int);
                                      v++) ...[
                                    TextSpan(
                                      text: quran.getVerse(
                                        section['surah'] as int,
                                        v,
                                        verseEndSymbol: true,
                                      ),
                                    ),
                                    const TextSpan(text: ' '),
                                  ],
                                ],
                              ),
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 22,
                                height: 2.15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // الشريط السفلي لرقم الصفحة
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'الصفحة $pageNumber من ${quran.totalPagesCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
