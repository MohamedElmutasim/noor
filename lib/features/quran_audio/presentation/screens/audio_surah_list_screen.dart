import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:noor/core/constants/app_colors.dart';
import 'audio_player_screen.dart';

class AudioSurahListScreen extends StatefulWidget {
  const AudioSurahListScreen({super.key});

  @override
  State<AudioSurahListScreen> createState() => _AudioSurahListScreenState();
}

class _AudioSurahListScreenState extends State<AudioSurahListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _downloadedSurahs = {};

  @override
  void initState() {
    super.initState();
    _checkDownloadedSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkDownloadedSurahs() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${docDir.path}/quran_audio');
      if (await audioDir.exists()) {
        final files = audioDir.listSync();
        final Set<int> downloaded = {};
        for (final file in files) {
          final fileName = file.uri.pathSegments.last;
          if (fileName.startsWith('surah_') && fileName.endsWith('.mp3')) {
            final numStr = fileName.substring(6, fileName.length - 4);
            final number = int.tryParse(numStr);
            if (number != null) {
              downloaded.add(number);
            }
          }
        }
        if (mounted) {
          setState(() {
            _downloadedSurahs.clear();
            _downloadedSurahs.addAll(downloaded);
          });
        }
      }
    } catch (_) {}
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
    final filteredSurahs = _getFilteredSurahs();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'التلاوات والاستماع',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // بطاقة معلومات القارئ
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
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
                      Icons.headphones_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تلاوة القرآن الكريم كاملاً',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'بصوت الشيخ مشاري راشد العفاسي (حفص عن عاصم)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شريط البحث
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
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
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
                  borderSide: const BorderSide(color: AppColors.border),
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
                ? const Center(
                    child: Text(
                      'لا توجد نتائج مطابقة لبحثك',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    itemCount: filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final surahNumber = filteredSurahs[index];
                      final nameArabic = quran.getSurahNameArabic(surahNumber);
                      final verseCount = quran.getVerseCount(surahNumber);
                      final place = _getPlaceArabic(quran.getPlaceOfRevelation(surahNumber));
                      final isDownloaded = _downloadedSurahs.contains(surahNumber);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        color: AppColors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AudioPlayerScreen(surahNumber: surahNumber),
                              ),
                            );
                            _checkDownloadedSurahs();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                // رقم السورة
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.primary, width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$surahNumber',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // معلومات السورة
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'سورة $nameArabic',
                                        style: GoogleFonts.amiri(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$place • $verseCount آية',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // شارة التنزيل وزر الاستماع
                                if (isDownloaded)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'محلي',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
