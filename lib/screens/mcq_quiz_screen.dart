import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/mcq_question.dart';
import '../models/user_progress.dart';
import '../models/section.dart';
import '../models/lesson.dart';
import '../services/mcq_service.dart';
import '../services/progress_service.dart';
import '../utils/logger.dart';
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

      // Check if this is the last question to mark quiz as completed
      if (questionIndex >= _questions.length - 1) {
        // Quiz completed - but don't auto-advance to results
        // User will need to click "View Results" button
      }
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Excellent work! You scored ${_scorePercentage.round()}%',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
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
      // If no section info, go back to course details
      Navigator.of(context).pop(true);
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
    // Go back to course details
    Navigator.of(context).pop(true);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.lessonTitle}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (!_isLoading && _questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentQuestionIndex + 1}/${_questions.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
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
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(
                  Icons.list,
                  size: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                label: Text(
                  'Back to Chapter Overview',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
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
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Card(
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
                  Text(question.question, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount:
                  _shuffledOptions[questionIndex]?.length ??
                  question.options.length,
              itemBuilder: (context, optionIndex) {
                // Use shuffled options if available, otherwise fall back to original
                final optionText =
                    _shuffledOptions[questionIndex]?[optionIndex] ??
                    question.options[optionIndex];

                return _buildOptionCard(
                  questionIndex,
                  optionIndex,
                  optionText,
                  isRevealed,
                  selectedIndex,
                  question.correctAnswerIndex,
                );
              },
            ),
          ),

          // Submit button or explanation
          if (isRevealed) ...[
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Explanation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (questionIndex < _questions.length - 1)
              ElevatedButton(
                onPressed: () {
                  _goToQuestion(questionIndex + 1);
                },
                child: const Text('Next Question'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  await _completeQuiz();
                },
                child: const Text('View Results'),
              ),
          ] else ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  selectedIndex != null
                      ? () => _submitAnswer(questionIndex)
                      : null,
              child: const Text('Submit Answer'),
            ),
          ],
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
        cardColor = theme.colorScheme.primaryContainer;
        borderColor = Colors.green;
        icon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        cardColor = theme.colorScheme.errorContainer;
        borderColor = Colors.red;
        icon = Icons.cancel;
        iconColor = Colors.red;
      }
    } else if (isSelected) {
      cardColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: cardColor,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      isSelected
                          ? (isRevealed
                              ? (isCorrect ? Colors.green : Colors.red)
                              : theme.colorScheme.primary)
                          : theme.colorScheme.surfaceVariant,
                  radius: 12,
                  child: Text(
                    String.fromCharCode(65 + optionIndex), // A, B, C, D
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(optionText, style: theme.textTheme.bodyLarge),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: iconColor, size: 20),
                ],
              ],
            ),
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
    // Use consistent, encouraging colors instead of score-based colors
    final celebrationColor = theme.colorScheme.primary;
    final successColor = Colors.green;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      barrierColor: Colors.black.withOpacity(0.8), // Solid dark background
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              theme.scaffoldBackgroundColor, // Explicit background color
          elevation: 24, // Add elevation for better visual separation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor, // Double ensure background
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon - always celebratory
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.emoji_events,
                      color: successColor,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quiz Completed!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great job finishing "${widget.lessonTitle}" quiz!',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Score display - neutral and encouraging
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: celebrationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: celebrationColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Score',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: celebrationColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_correctAnswers/${_questions.length} (${_scorePercentage.round()}%)',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: celebrationColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getEncouragingMessage(_scorePercentage),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: celebrationColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // What's next section
                Text(
                  'What would you like to do next?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Retake quiz option
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('retake'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Retake Quiz',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Practice makes perfect!',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSecondary.withOpacity(
                              0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Next lesson option - only show if there's actually a next lesson
                if (_hasNextLesson()) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop('next'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      icon: Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Continue to Next Lesson',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],

                // Back to course option
                Container(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop('back'),
                    icon: Icon(
                      Icons.list,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    label: Text(
                      'Back to Chapter Overview',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
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
          Navigator.of(context).pop(true); // Go back to course details
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
