import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:noor/core/constants/app_colors.dart';

class AudioPlayerScreen extends StatefulWidget {
  final int surahNumber;

  const AudioPlayerScreen({
    super.key,
    required this.surahNumber,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final AudioPlayer _player;
  late int _currentSurahNumber;

  bool _isInitializing = true;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _localFilePath = '';
  CancelToken? _cancelToken;

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  String get _audioUrl =>
      'https://server8.mp3quran.net/afs/${_currentSurahNumber.toString().padLeft(3, '0')}.mp3';

  @override
  void initState() {
    super.initState();
    _currentSurahNumber = widget.surahNumber;
    _player = AudioPlayer();
    _setupPlayerListeners();
    _checkFileAndStartPlayback();
  }

  void _setupPlayerListeners() {
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _durationSubscription = _player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });

    _positionSubscription = _player.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });

    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  Future<void> _checkFileAndStartPlayback() async {
    setState(() {
      _isInitializing = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${docDir.path}/quran_audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      _localFilePath =
          '${audioDir.path}/surah_${_currentSurahNumber.toString().padLeft(3, '0')}.mp3';
      final file = File(_localFilePath);
      final exists = await file.exists();

      if (mounted) {
        setState(() {
          _isDownloaded = exists;
          _isInitializing = false;
        });
      }

      // تشغيل الصوت: من الذاكرة المحلية إذا توفر، وإلا عبر البث
      await _playSource(exists);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _playSource(bool isLocal) async {
    try {
      if (isLocal) {
        await _player.stop();
        await _player.play(DeviceFileSource(_localFilePath));
      } else {
        await _player.stop();
        await _player.play(UrlSource(_audioUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تشغيل المقطع الصوتي، يرجى التحقق من الاتصال بالإنترنت'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _playSource(_isDownloaded);
    }
  }

  Future<void> _downloadSurah() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _cancelToken = CancelToken();
    final tempFilePath = '$_localFilePath.tmp';

    try {
      final dio = Dio();
      await dio.download(
        _audioUrl,
        tempFilePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.rename(_localFilePath);
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم اكتمال تنزيل السورة بنجاح، يمكنك الآن الاستماع دون إنترنت',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        final isCanceled = e is DioException && e.type == DioExceptionType.cancel;
        if (!isCanceled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء تنزيل الملف، يرجى المحاولة لاحقاً'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _changeSurah(int newSurah) {
    if (newSurah < 1 || newSurah > quran.totalSurahCount) return;
    _cancelToken?.cancel();
    _player.stop();
    setState(() {
      _currentSurahNumber = newSurah;
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    _checkFileAndStartPlayback();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _cancelToken?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahName = quran.getSurahNameArabic(_currentSurahNumber);
    final placeOfRevelation =
        quran.getPlaceOfRevelation(_currentSurahNumber).toLowerCase() == 'makkah'
            ? 'مكية'
            : 'مدنية';
    final verseCount = quran.getVerseCount(_currentSurahNumber);
    final isPlaying = _playerState == PlayerState.playing;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'سورة $surahName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // بطاقة السورة المزخرفة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // رقم السورة وشارتها
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'السورة رقم $_currentSurahNumber',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // اسم السورة بالخط القرآني الأصيل
                    Text(
                      'سورة $surahName',
                      style: GoogleFonts.amiri(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // معلومات السورة
                    Text(
                      '$placeOfRevelation • $verseCount آية',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // اسم القارئ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'القارئ: مشاري راشد العفاسي',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // شارة نوع التشغيل (استماع محلي بدون إنترنت أو بث مباشر)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isDownloaded
                      ? Colors.green.withValues(alpha: 0.12)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDownloaded ? Colors.green : AppColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDownloaded
                          ? Icons.offline_pin_rounded
                          : Icons.wifi_rounded,
                      size: 18,
                      color: _isDownloaded ? Colors.green.shade800 : AppColors.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isDownloaded
                          ? 'تشغيل محلي (بدون إنترنت)'
                          : 'بث مباشر عبر الإنترنت',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isDownloaded
                            ? Colors.green.shade900
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // شريط تقدم الصوت
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.primary,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayColor: AppColors.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: (_position.inMilliseconds > 0 &&
                              _duration.inMilliseconds > 0 &&
                              _position.inMilliseconds <= _duration.inMilliseconds)
                          ? _position.inMilliseconds.toDouble()
                          : 0.0,
                      max: (_duration.inMilliseconds > 0)
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                      onChanged: (val) {
                        _player.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // أزرار التحكم بالتشغيل
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // السورة السابقة
                  IconButton(
                    iconSize: 30,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: _currentSurahNumber > 1
                        ? AppColors.primaryDark
                        : AppColors.border,
                    tooltip: 'السورة السابقة',
                    onPressed: _currentSurahNumber > 1
                        ? () => _changeSurah(_currentSurahNumber - 1)
                        : null,
                  ),

                  // إرجاع 10 ثوانٍ
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.replay_10_rounded),
                    color: AppColors.primaryDark,
                    tooltip: 'إرجاع 10 ثوانٍ',
                    onPressed: () {
                      final newPos = _position - const Duration(seconds: 10);
                      _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),
                  const SizedBox(width: 10),

                  // زر التشغيل والإيقاف الرئيسي
                  _isInitializing
                      ? const SizedBox(
                          width: 64,
                          height: 64,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _togglePlayPause,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(18),
                              elevation: 0,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                            ),
                          ),
                        ),
                  const SizedBox(width: 10),

                  // تقديم 10 ثوانٍ
                  IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.forward_10_rounded),
                    color: AppColors.primaryDark,
                    tooltip: 'تقديم 10 ثوانٍ',
                    onPressed: () {
                      final newPos = _position + const Duration(seconds: 10);
                      _player.seek(newPos > _duration ? _duration : newPos);
                    },
                  ),

                  // السورة التالية
                  IconButton(
                    iconSize: 30,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: _currentSurahNumber < quran.totalSurahCount
                        ? AppColors.primaryDark
                        : AppColors.border,
                    tooltip: 'السورة التالية',
                    onPressed: _currentSurahNumber < quran.totalSurahCount
                        ? () => _changeSurah(_currentSurahNumber + 1)
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // قسم التنزيل وحفظ السورة
              if (_isDownloading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'جاري تنزيل السورة...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          minHeight: 8,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isDownloaded)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'تم الحفظ للاستماع بدون إنترنت',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _downloadSurah,
                    icon: const Icon(Icons.file_download_rounded, size: 22),
                    label: const Text(
                      'تنزيل السورة للاستماع بدون إنترنت',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
