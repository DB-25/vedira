import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSize { small, medium, large }

class LessonController extends ChangeNotifier {
  // Font size preferences
  FontSize _fontSize = FontSize.medium;
  static const String _fontSizeKey = 'lesson_font_size';
  bool _isLoading = true;

  // TOC and scroll control
  final TocController _tocController = TocController();
  ScrollController? _scrollController;
  int _currentTocIndex = -1;
  bool _showScrollToTop = false;

  // Reader state
  bool _isCompleting = false;
  bool _isCompleted = false;

  // Constructor - loads preferences
  LessonController() {
    _loadPreferences();
  }

  // Getters
  FontSize get fontSize => _fontSize;
  bool get isLoading => _isLoading;
  TocController get tocController => _tocController;
  ScrollController? get scrollController => _scrollController;
  int get currentTocIndex => _currentTocIndex;
  bool get showScrollToTop => _showScrollToTop;
  bool get isCompleting => _isCompleting;
  bool get isCompleted => _isCompleted;

  // Set scroll controller
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
    // Add scroll listener to show/hide scroll-to-top button
    _scrollController?.addListener(_scrollListener);
  }

  // Scroll listener for FAB visibility
  void _scrollListener() {
    if (_scrollController == null) return;

    final offset = _scrollController!.offset;
    final showButton = offset > 300;

    if (_showScrollToTop != showButton) {
      _showScrollToTop = showButton;
      notifyListeners();
    }
  }

  // Load saved font size preference
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFontSize = prefs.getString(_fontSizeKey);
      if (savedFontSize != null) {
        _fontSize = FontSize.values.firstWhere(
          (e) => e.toString() == savedFontSize,
          orElse: () => FontSize.medium,
        );
      }
    } catch (e) {
      debugPrint('Error loading font preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set font size and save preference
  Future<void> setFontSize(FontSize size) async {
    if (_fontSize == size) return;
    _fontSize = size;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontSizeKey, _fontSize.toString());
    } catch (e) {
      debugPrint('Error saving font preferences: $e');
    }

    notifyListeners();
  }

  // Scroll to a specific TOC item
  void scrollToTocItem(String id) {
    // Use the TocController to scroll to the item
    if (_scrollController != null) {
      // Find the position to scroll to
      // This is a simplified approach, would need to be adapted based on the actual TOC implementation
      _scrollController?.animateTo(
        0, // Replace with actual position calculation
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Scroll to top
  void scrollToTop() {
    _scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Update current TOC index based on scroll position
  void updateCurrentTocIndex(int index) {
    if (_currentTocIndex != index) {
      _currentTocIndex = index;
      notifyListeners();
    }
  }

  // Set lesson completion status
  void setCompleted(bool completed) {
    _isCompleted = completed;
    notifyListeners();
  }

  // Set lesson completing status (during API call)
  void setCompleting(bool completing) {
    _isCompleting = completing;
    notifyListeners();
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController = null;
    super.dispose();
  }
}
