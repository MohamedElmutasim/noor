import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider extends ChangeNotifier {
  static const String _bookmarkKey = 'quran_saved_page';

  int _savedPage = 1;
  bool _isLoading = true;

  BookmarkProvider() {
    _loadBookmark();
  }

  int get savedPage => _savedPage;
  bool get isLoading => _isLoading;

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPage = prefs.getInt(_bookmarkKey) ?? 1;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveBookmark(int pageNumber) async {
    _savedPage = pageNumber;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bookmarkKey, pageNumber);
  }
}
