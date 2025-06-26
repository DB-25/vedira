import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/mcq_question.dart';
import '../models/user_progress.dart';
import '../models/section.dart';
import '../models/lesson.dart';
import '../services/mcq_service.dart';
import '../services/progress_service.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../components/custom_app_bar.dart';
import '../screens/lesson_view_screen.dart';

class McqQuizScreen extends StatefulWidget {
  final String courseId;
  final String chapterId;
  final String lessonId;
  final String lessonTitle;
  final Section? section;
  final int? currentLessonIndex;

  const McqQuizScreen({
    super.key,
    required this.courseId,
    required this.chapterId,
    required this.lessonId,
    required this.lessonTitle,
    this.section,
    this.currentLessonIndex,
  });

  @override
  State<McqQuizScreen> createState() => _McqQuizScreenState();
}

class _McqQuizScreenState extends State<McqQuizScreen> {
  final McqService _mcqService = McqService();
  final ProgressService _progressService = ProgressService();
  final String _tag = 'McqQuizScreen';
  late PageController _pageController;

  List<McqQuestion> _questions = [];
  Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  Map<int, bool> _answersRevealed = {}; // questionIndex -> isRevealed
  Map<int, bool> _actualCorrectness =
      {}; // questionIndex -> isActuallyCorrect (based on UI)
  Map<int, List<int>> _shuffledIndexes =
      {}; // questionIndex -> shuffled order mapping
  Map<int, List<String>> _shuffledOptions =
      {}; // questionIndex -> shuffled options
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentQuestionIndex = 0;
  bool _quizCompleted = false;
  DateTime? _quizStartTime;
  bool _progressSaved = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _quizStartTime = DateTime.now();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mcqService.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final questions = await _mcqService.fetchQuestions(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
      );

      // Shuffle options for each question
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final originalOptions = question.options;

        // Create a list of indexes [0, 1, 2, 3] and shuffle them
        final indexes = List.generate(originalOptions.length, (index) => index);
        indexes.shuffle();

        // Create shuffled options using the shuffled indexes
        final shuffledOptions =
            indexes.map((index) => originalOptions[index]).toList();

        // Store the shuffled data
        _shuffledIndexes[i] = indexes;
        _shuffledOptions[i] = shuffledOptions;

        // Debug logging to verify shuffling
        Logger.i(
          _tag,
          'Question $i: Original correct answer at index ${question.correctAnswerIndex}',
        );
        Logger.i(_tag, 'Question $i: Shuffle mapping: $indexes');
        Logger.i(
          _tag,
          'Question $i: Original correct answer is now at shuffled index ${indexes.indexOf(question.correctAnswerIndex)}',
        );
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
        _hasError = questions.isEmpty;
        _errorMessage =
            questions.isEmpty
                ? 'No quiz questions available for this lesson.'
                : '';
      });

      Logger.i(
        _tag,
        'MCQ questions loaded successfully',
        data: {'questionCount': questions.length},
      );
    } catch (e) {
      Logger.e(_tag, 'Error loading MCQ questions', error: e);
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load quiz questions. Please try again.';
      });
    }
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    setState(() {
      _selectedAnswers[questionIndex] = optionIndex;
    });
  }

  void _revealAnswer(int questionIndex) {
    setState(() {
      _answersRevealed[questionIndex] = true;
    });
  }

  void _submitAnswer(int questionIndex) {
    if (_selectedAnswers.containsKey(questionIndex)) {
      // Get the selected index in the shuffled options
      final selectedShuffledIndex = _selectedAnswers[questionIndex];

      // Map back to the original index using the shuffle mapping
      final shuffledIndexes = _shuffledIndexes[questionIndex]!;
      final originalSelectedIndex = shuffledIndexes[selectedShuffledIndex!];

      // Check if the original selected index matches the correct answer
      final isCorrect =
          originalSelectedIndex == _questions[questionIndex].correctAnswerIndex;
      _actualCorrectness[questionIndex] = isCorrect;

      _revealAnswer(questionIndex);

      // Don't auto-show explanation - let user choose via the bottom action bar
      // This gives users control over when they want to see explanations
    }
  }



  void _showExplanationBottomSheet(String explanation, int questionIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: colorScheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
                      BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Explanation',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                    ),
                  ),
                ],
              ),
            ),

            // Explanation content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  explanation,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), // Added bottom padding
              child: SafeArea(
                child: Row(
                  children: [
                    if (questionIndex < _questions.length - 1) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _goToQuestion(questionIndex + 1);
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next Question'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _completeQuiz();
                          },
                          icon: const Icon(Icons.flag),
                          label: const Text('View Results'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToQuestion(int questionIndex) {
    if (questionIndex >= 0 && questionIndex < _questions.length) {
      setState(() {
        _currentQuestionIndex = questionIndex;
      });
      _pageController.animateToPage(
        questionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildBottomActionBar() {
    if (_isLoading || _hasError || _quizCompleted) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedIndex = _selectedAnswers[_currentQuestionIndex];
    final isRevealed = _answersRevealed[_currentQuestionIndex] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // View Explanation button (only show if revealed and explanation exists)
            if (isRevealed && currentQuestion.explanation.isNotEmpty) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _showExplanationBottomSheet(
                    currentQuestion.explanation,
                    _currentQuestionIndex,
                  ),
                  icon: Icon(Icons.lightbulb_outline, size: 18),
                  label: Text('Explain'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Main action button
            Expanded(
              flex: 2,
              child: _buildMainActionButton(selectedIndex, isRevealed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(int? selectedIndex, bool isRevealed) {
    if (!isRevealed) {
      // Show Submit Answer button
      return ElevatedButton.icon(
        onPressed: selectedIndex != null
            ? () => _submitAnswer(_currentQuestionIndex)
            : null,
        icon: Icon(Icons.check, size: 18),
        label: Text('Submit Answer'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    } else {
      // Show Next Question or View Results button
      if (_currentQuestionIndex < _questions.length - 1) {
        return ElevatedButton.icon(
          onPressed: () => _goToQuestion(_currentQuestionIndex + 1),
          icon: Icon(Icons.arrow_forward, size: 18),
          label: Text('Next Question'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
      } else {
        return ElevatedButton.icon(
          onPressed: () async => await _completeQuiz(),
          icon: Icon(Icons.flag, size: 18),
          label: Text('View Results'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
      }
    }
  }

  Future<void> _completeQuiz() async {
    setState(() {
      _quizCompleted = true;
    });

    // Save quiz attempt to progress
    if (!_progressSaved) {
      await _saveQuizAttempt();
    }

    // Show completion dialog instead of just showing results
    if (mounted) {
      await _showCompletionDialog();
    }
  }

  Future<void> _saveQuizAttempt() async {
    if (_quizStartTime == null || _progressSaved) return;

    try {
      final now = DateTime.now();
      final timeSpentSeconds = now.difference(_quizStartTime!).inSeconds;

      // Create the quiz attempt
      final quizAttempt = QuizAttempt(
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        score: _correctAnswers,
        totalQuestions: _questions.length,
        scorePercentage: _scorePercentage,
        completedAt: now,
        timeSpentSeconds: timeSpentSeconds,
        answers: _selectedAnswers,
        correctAnswers: _getCorrectAnswersMap(),
      );

      // Save to progress service
      final success = await _progressService.saveQuizAttempt(
        courseId: widget.courseId,
        chapterId: widget.chapterId,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
        quizAttempt: quizAttempt,
      );

      if (success) {
        setState(() {
          _progressSaved = true;
        });
        Logger.i(
          _tag,
          'Quiz attempt saved successfully',
          data: {
            'score': _correctAnswers,
            'totalQuestions': _questions.length,
            'scorePercentage': _scorePercentage,
          },
        );

        // Show achievement notification if score is high
        if (_scorePercentage >= 90 && mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.star, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Excellent work! You scored ${_scorePercentage.round()}%',
                  ),
                ],
              ),
              backgroundColor: theme.colorScheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        Logger.e(_tag, 'Failed to save quiz attempt');
      }
    } catch (e) {
      Logger.e(_tag, 'Error saving quiz attempt', error: e);
    }
  }

  Map<int, bool> _getCorrectAnswersMap() {
    // Return the correctness as determined by the UI
    return Map<int, bool>.from(_actualCorrectness);
  }

  void _resetQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _answersRevealed.clear();
      _actualCorrectness.clear();
      _shuffledIndexes.clear();
      _shuffledOptions.clear();
      _currentQuestionIndex = 0;
      _quizCompleted = false;
      _quizStartTime = DateTime.now();
      _progressSaved = false;
    });

    // Re-shuffle the options for a fresh quiz experience
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final originalOptions = question.options;

      // Create a list of indexes [0, 1, 2, 3] and shuffle them
      final indexes = List.generate(originalOptions.length, (index) => index);
      indexes.shuffle();

      // Create shuffled options using the shuffled indexes
      final shuffledOptions =
          indexes.map((index) => originalOptions[index]).toList();

      // Store the shuffled data
      _shuffledIndexes[i] = indexes;
      _shuffledOptions[i] = shuffledOptions;
    }

    // Wait for the widget tree to rebuild before trying to animate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToNextLesson() {
    // Check if we have section information to determine next lesson
    if (widget.section == null || widget.currentLessonIndex == null) {
      // If no section info, go back to course details with quiz completion data
      Navigator.of(context).pop({
        'quizCompleted': true,
        'score': _correctAnswers,
        'totalQuestions': _questions.length,
        'scorePercentage': _scorePercentage,
      });
      return;
    }

    final section = widget.section!;
    final currentIndex = widget.currentLessonIndex!;

    // Check if there's a next lesson in this section
    if (currentIndex + 1 < section.lessons.length) {
      final nextLesson = section.lessons[currentIndex + 1];

      // Only navigate if the next lesson is generated/available
      if (nextLesson.generated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => LessonViewScreen(
                  courseId: widget.courseId,
                  chapterId: widget.chapterId,
                  lessonId: nextLesson.id,
                  lessonTitle: nextLesson.title,
                  lesson: nextLesson,
                ),
          ),
        );
        return;
      }
    }

    // No next lesson available or next lesson not generated
    // Go back to course details with quiz completion data
    Navigator.of(context).pop({
      'quizCompleted': true,
      'score': _correctAnswers,
      'totalQuestions': _questions.length,
      'scorePercentage': _scorePercentage,
    });
  }

  int get _correctAnswers {
    // Use the correctness as determined by the UI when answers were submitted
    return _actualCorrectness.values.where((isCorrect) => isCorrect).length;
  }

  double get _scorePercentage {
    if (_questions.isEmpty) return 0.0;
    return (_correctAnswers / _questions.length) * 100;
  }

  bool _hasNextLesson() {
    // Check if we have section information to determine next lesson
    if (widget.section == null || widget.currentLessonIndex == null) {
      Logger.i(
        _tag,
        'No section info: section=${widget.section != null}, currentIndex=${widget.currentLessonIndex}',
      );
      return false;
    }

    final section = widget.section!;
    final currentIndex = widget.currentLessonIndex!;

    Logger.i(
      _tag,
      'Checking next lesson: currentIndex=$currentIndex, totalLessons=${section.lessons.length}',
    );

    // Check if there's a next lesson in this section that is generated/available
    if (currentIndex + 1 < section.lessons.length) {
      final nextLesson = section.lessons[currentIndex + 1];
      Logger.i(
        _tag,
        'Next lesson found: ${nextLesson.title}, generated=${nextLesson.generated}',
      );
      return nextLesson.generated;
    }

    Logger.i(_tag, 'No next lesson available');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the body background from theme manager
    final bodyBackgroundColor = colorScheme.bodyBackground;

    return Scaffold(
      backgroundColor: bodyBackgroundColor,
      appBar: CustomAppBar(
        title: 'Quiz: ${widget.lessonTitle}',
        actions: [
          if (!_isLoading && _questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading quiz questions...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Quiz Available',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Try Again button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadQuestions,
                  child: const Text('Try Again'),
                ),
              ),

              // Show next lesson option if available
              if (_hasNextLesson()) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToNextLesson(),
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    label: const Text('Continue to Next Lesson'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // Back to chapter option
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.list,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                label: Text(
                  'Back to Chapter Overview',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_quizCompleted) {
      return _buildQuizResults();
    }

    return _buildQuizContent();
  }

  Widget _buildQuizContent() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentQuestionIndex = index;
        });
      },
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return _buildQuestionCard(index);
      },
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    final selectedIndex = _selectedAnswers[questionIndex];
    final isRevealed = _answersRevealed[questionIndex] ?? false;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (questionIndex + 1) / _questions.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Card(
            color: theme.colorScheme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${questionIndex + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.question, 
                    style: theme.textTheme.titleLarge,
                    softWrap: true,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options - using Flexible to allow natural sizing
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Build all options dynamically
                  for (int optionIndex = 0; optionIndex < (_shuffledOptions[questionIndex]?.length ?? question.options.length); optionIndex++)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        bottom: optionIndex < (_shuffledOptions[questionIndex]?.length ?? question.options.length) - 1 ? 8 : 0,
                      ),
                      child: _buildOptionCard(
                        questionIndex,
                        optionIndex,
                        _shuffledOptions[questionIndex]?[optionIndex] ?? question.options[optionIndex],
                        isRevealed,
                        selectedIndex,
                        question.correctAnswerIndex,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons are now in the bottom navigation bar
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    int questionIndex,
    int optionIndex,
    String optionText,
    bool isRevealed,
    int? selectedIndex,
    int correctIndex,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == optionIndex;

    // For shuffled options, we need to check if this shuffled option corresponds to the original correct answer
    bool isCorrect = false;
    if (isRevealed) {
      final shuffledIndexes = _shuffledIndexes[questionIndex]!;
      final originalIndexForThisOption = shuffledIndexes[optionIndex];
      isCorrect = originalIndexForThisOption == correctIndex;
    }

    Color? cardColor;
    Color? borderColor;
    IconData? icon;
    Color? iconColor;

    if (isRevealed) {
      if (isCorrect) {
        cardColor = theme.colorScheme.success.withValues(alpha: 0.5); // Increased to 0.5
        borderColor = theme.colorScheme.success;
        icon = Icons.check_circle;
        iconColor = theme.colorScheme.success;
      } else if (isSelected && !isCorrect) {
        cardColor = theme.colorScheme.error.withValues(alpha: 0.5); // Increased to 0.5
        borderColor = theme.colorScheme.error;
        icon = Icons.cancel;
        iconColor = theme.colorScheme.error;
      }
    } else if (isSelected) {
      cardColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
    }

    return Card(
      color: cardColor ?? theme.colorScheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor ?? Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap:
            isRevealed
                ? null
                : () => _selectAnswer(questionIndex, optionIndex),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isSelected
                        ? (isRevealed
                            ? (isCorrect ? theme.colorScheme.success : theme.colorScheme.error)
                            : theme.colorScheme.primary)
                        : theme.colorScheme.surfaceContainerHighest,
                radius: 12,
                child: Text(
                  String.fromCharCode(65 + optionIndex), // A, B, C, D
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  optionText,
                  style: theme.textTheme.bodyLarge,
                  softWrap: true,
                  textAlign: TextAlign.left,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: iconColor, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizResults() {
    // This should not be reached since we use completion dialog now
    // But keeping as fallback just in case

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: const CircularProgressIndicator()),
    );
  }

  Future<void> _showCompletionDialog() async {
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: colorScheme.shadow.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with celebration
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Simple checkmark
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: colorScheme.success,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Quiz Complete!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You answered $_correctAnswers out of ${_questions.length} questions correctly',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Primary action - Continue or Retake based on context
                      if (_hasNextLesson()) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop('next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Continue Learning'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Secondary actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop('retake'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: colorScheme.outline),
                              ),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop('back'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: colorScheme.outline),
                              ),
                              icon: const Icon(Icons.list, size: 18),
                              label: const Text('Overview'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Handle user's choice
    if (result != null && mounted) {
      switch (result) {
        case 'retake':
          _resetQuiz();
          break;
        case 'next':
          _navigateToNextLesson();
          break;
        case 'back':
          // Return with quiz completion result to refresh course details
          Navigator.of(context).pop({
            'quizCompleted': true,
            'score': _correctAnswers,
            'totalQuestions': _questions.length,
            'scorePercentage': _scorePercentage,
          });
          break;
      }
    }
  }

  String _getEncouragingMessage(double scorePercentage) {
    if (scorePercentage >= 90) return 'Outstanding work! 🌟';
    if (scorePercentage >= 80) return 'Excellent progress! 🎉';
    if (scorePercentage >= 70) return 'Well done! Keep it up! 👏';
    if (scorePercentage >= 60) return 'Good effort! You\'re learning! 📚';
    return 'Great attempt! Learning is a journey! 🚀';
  }
}
