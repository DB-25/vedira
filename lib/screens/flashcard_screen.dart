import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/flashcard.dart';
import '../models/section.dart';
import '../models/user_progress.dart';
import '../services/flashcard_service.dart';
import '../services/progress_service.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../components/custom_app_bar.dart';

class FlashcardScreen extends StatefulWidget {
  final String courseId;
  final String chapterId;
  final String lessonId;
  final String lessonTitle;
  final Section? section;
  final int? currentLessonIndex;

  const FlashcardScreen({
    super.key,
    required this.courseId,
    required this.chapterId,
    required this.lessonId,
    required this.lessonTitle,
    this.section,
    this.currentLessonIndex,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with TickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService();
  final ProgressService _progressService = ProgressService();
  final String _tag = 'FlashcardScreen';
  late PageController _pageController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late DateTime _sessionStartTime;

  List<Flashcard> _flashcards = [];
  Map<int, bool> _isFlipped = {}; // Track which cards are flipped
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _pageController = PageController();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    _loadFlashcards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipController.dispose();
    _flashcardService.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final flashcards = await _flashcardService.fetchFlashcards(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
      );

      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
        _hasError = flashcards.isEmpty;
        _errorMessage =
            flashcards.isEmpty
                ? 'No flashcards available for this lesson.'
                : '';
      });

      Logger.i(
        _tag,
        'Flashcards loaded successfully',
        data: {'cardCount': flashcards.length},
      );
    } catch (e) {
      Logger.e(_tag, 'Error loading flashcards', error: e);
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load flashcards. Please try again.';
      });
    }
  }

  void _flipCard(int cardIndex) {
    setState(() {
      _isFlipped[cardIndex] = !(_isFlipped[cardIndex] ?? false);
    });
    
    if (_isFlipped[cardIndex] ?? false) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _nextCard() {
    if (_currentCardIndex < _flashcards.length - 1) {
      setState(() {
        _currentCardIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _flipController.reset();
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _flipController.reset();
    }
  }

  void _resetCards() {
    setState(() {
      _currentCardIndex = 0;
      _isFlipped.clear();
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _flipController.reset();
  }

  Future<void> _saveFlashcardProgress() async {
    try {
      final completedAt = DateTime.now();
      final timeSpentSeconds = completedAt.difference(_sessionStartTime).inSeconds;

      final flashcardAttempt = FlashcardAttempt(
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        totalCards: _flashcards.length,
        completedAt: completedAt,
        timeSpentSeconds: timeSpentSeconds,
        metadata: {
          'cardsFlipped': _isFlipped.values.where((flipped) => flipped).length,
          'sessionType': 'flashcard_review',
        },
      );

      final success = await _progressService.saveFlashcardAttempt(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        flashcardAttempt: flashcardAttempt,
      );

      if (success) {
        Logger.i(_tag, 'Flashcard progress saved successfully', data: {
          'lessonId': widget.lessonId,
          'totalCards': _flashcards.length,
          'timeSpentMinutes': (timeSpentSeconds / 60).ceil(),
        });
      } else {
        Logger.w(_tag, 'Failed to save flashcard progress');
      }
    } catch (e) {
      Logger.e(_tag, 'Error saving flashcard progress', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Flashcards',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _buildFlashcardContent(),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading flashcards...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadFlashcards,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(),
        
        // Lesson info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lessonTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_flashcards.length} flashcards',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // Flashcard area
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCardIndex = index;
              });
              _flipController.reset();
            },
            itemCount: _flashcards.length,
            itemBuilder: (context, index) {
              return _buildFlashcardPage(index);
            },
          ),
        ),

        // Navigation controls
        _buildNavigationControls(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _flashcards.isNotEmpty ? (_currentCardIndex + 1) / _flashcards.length : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentCardIndex + 1} of ${_flashcards.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardPage(int index) {
    final flashcard = _flashcards[index];
    final isFlipped = _isFlipped[index] ?? false;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: () => _flipCard(index),
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final isShowingFront = _flipAnimation.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * math.pi),
              child: Card(
                elevation: 8,
                shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isShowingFront
                          ? [
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            ]
                          : [
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                            ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: isShowingFront
                        ? _buildCardFront(flashcard)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildCardBack(flashcard),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(Flashcard flashcard) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Question',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.help_outline,
              color: colorScheme.primary,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Text(
              flashcard.question,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to reveal answer',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(Flashcard flashcard) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Answer',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.lightbulb_outline,
              color: colorScheme.secondary,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: Text(
              flashcard.answer,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to show question',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: _currentCardIndex > 0
                ? OutlinedButton(
                    onPressed: _previousCard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.outline),
                      foregroundColor: colorScheme.onSurface,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 18),
                        const SizedBox(width: 8),
                        const Text('Previous'),
                      ],
                    ),
                  )
                : OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 18),
                        const SizedBox(width: 8),
                        const Text('Previous'),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          
          // Reset button
          FilledButton.icon(
            onPressed: _resetCards,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Next/Finish button
          Expanded(
            child: _currentCardIndex < _flashcards.length - 1
                ? FilledButton(
                    onPressed: _nextCard,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Next'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  )
                : FilledButton(
                    onPressed: () async {
                      await _saveFlashcardProgress();
                      if (mounted) {
                        Navigator.of(context).pop({
                          'flashcardsCompleted': true,
                          'totalCards': _flashcards.length,
                        });
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.tertiary,
                      foregroundColor: colorScheme.onTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Complete'),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, size: 18),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 