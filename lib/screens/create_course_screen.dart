import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../screens/course_details_screen.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import '../components/custom_app_bar.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final String _tag = 'CreateCourseScreen';

  // Controllers
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _customInstructionsController = TextEditingController();
  final TextEditingController _totalTimeController = TextEditingController();
  final TextEditingController _customTimelineController = TextEditingController();

  // Onboarding state
  int _currentStep = 0;
  bool _isLoading = false;
  String _selectedPath = ''; // 'scratch' or 'document'
  
  // User inputs
  String _learningGoal = '';
  String _experienceLevel = '';
  String _learningStyle = '';
  String _dailyTimeCommitment = '';
  String _totalTimeframe = '';
  bool _hasCustomTimeline = false;
  
  // Document upload variables
  PlatformFile? _selectedFile;
  String? _documentBase64;
  bool _isUploadingFile = false;
  
  // Loading animation
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  int _elapsedSeconds = 0;
  String _loadingMessage = "Analyzing your request...";

  // Step data
  final List<String> _topicSuggestions = [
    'Learning to Read', 'Basic Math', 'Cooking for Beginners', 'Drawing',
    'Spanish Language', 'Guitar Playing', 'Gardening', 'Photography',
    'Python Programming', 'Digital Marketing', 'Web Development', 'Finance & Investing',
    'Advanced Physics', 'Machine Learning', 'Quantum Computing', 'Medical Terminology'
  ];

  final List<Map<String, String>> _learningGoals = [
    {'id': 'overview', 'title': 'Get a Quick Overview', 'desc': 'Learn the basics and main concepts'},
    {'id': 'practical', 'title': 'Build Practical Skills', 'desc': 'Focus on hands-on application and real-world use'},
    {'id': 'fun', 'title': 'Learn for Fun & Hobby', 'desc': 'Enjoyable learning for personal interest'},
    {'id': 'deep', 'title': 'Deep Understanding', 'desc': 'Comprehensive, detailed knowledge'},
    {'id': 'academic', 'title': 'Academic Success', 'desc': 'Help with school, homework, or exams'},
    {'id': 'career', 'title': 'Career Development', 'desc': 'Professional growth and job skills'},
  ];

  final List<Map<String, String>> _experienceLevels = [
    {'id': 'complete_beginner', 'title': 'Complete Beginner', 'desc': 'Never learned this before - start from the very beginning'},
    {'id': 'some_knowledge', 'title': 'Some Knowledge', 'desc': 'Know a little bit, familiar with some basics'},
    {'id': 'experienced', 'title': 'Experienced', 'desc': 'Pretty good at this, want to learn more or fill gaps'},
    {'id': 'expert', 'title': 'Expert Level', 'desc': 'Already very skilled, looking for advanced topics'},
  ];

  final List<Map<String, String>> _learningStyles = [
    {'id': 'structured', 'title': 'Structured & Sequential', 'desc': 'Step-by-step lessons, building up gradually'},
    {'id': 'practical_focused', 'title': 'Practical & Applied', 'desc': 'Focus on real-world applications and use cases'},
    {'id': 'theory_first', 'title': 'Concept First', 'desc': 'Understand theory before applying knowledge'},
    {'id': 'examples_heavy', 'title': 'Example-Heavy', 'desc': 'Lots of examples, case studies, and scenarios'},
    {'id': 'quiz_focused', 'title': 'Test & Reinforce', 'desc': 'Learn through quizzes and active recall'},
  ];

  final List<Map<String, String>> _dailyTimeOptions = [
    {'id': '15min', 'title': '15-20 minutes', 'desc': 'Quick sessions - perfect for busy schedules'},
    {'id': '30min', 'title': '30-45 minutes', 'desc': 'Standard pace - like a TV episode'},
    {'id': '1hour', 'title': '1-2 hours', 'desc': 'Focused study - like a class period'},
    {'id': '2hour+', 'title': '2+ hours', 'desc': 'Deep learning - weekend or evening sessions'},
  ];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    Logger.i(_tag, 'Screen initialized');
  }

  @override
  void dispose() {
    _topicController.dispose();
    _customInstructionsController.dispose();
    _totalTimeController.dispose();
    _customTimelineController.dispose();
    _loadingController.dispose();
    Logger.i(_tag, 'Screen disposed');
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  String _generateTimelineString() {
    if (_hasCustomTimeline && _customTimelineController.text.isNotEmpty) {
      return _customTimelineController.text;
    }
    
    // Generate timeline based on daily commitment and total time
    String dailyTime = _dailyTimeCommitment;
    String totalTime = _totalTimeframe;
    
    if (dailyTime.isNotEmpty && totalTime.isNotEmpty) {
      return '$totalTime with $dailyTime daily';
    } else if (totalTime.isNotEmpty) {
      return totalTime;
    } else {
      return '2 weeks'; // fallback
    }
  }

  String _generateDifficultyString() {
    // Map experience level to difficulty
    switch (_experienceLevel) {
      case 'complete_beginner':
        return 'beginner';
      case 'some_knowledge':
        return 'intermediate';
      case 'experienced':
        return 'advanced';
      case 'expert':
        return 'expert';
      default:
        return 'intermediate';
    }
  }

  String _generateCustomInstructions() {
    List<String> instructions = [];
    
    if (_learningGoal.isNotEmpty) {
      String goalText = _learningGoals.firstWhere((g) => g['id'] == _learningGoal)['title'] ?? '';
      instructions.add('Learning goal: $goalText');
    }
    
    if (_learningStyle.isNotEmpty) {
      String styleText = _learningStyles.firstWhere((s) => s['id'] == _learningStyle)['title'] ?? '';
      instructions.add('Learning style: $styleText');
    }
    
    if (_dailyTimeCommitment.isNotEmpty) {
      instructions.add('Available time per day: $_dailyTimeCommitment');
    }
    
    if (_customInstructionsController.text.isNotEmpty) {
      instructions.add(_customInstructionsController.text);
    }
    
    return instructions.join('. ');
  }

  void _startLoadingTimer() {
    _loadingController.repeat();
    Future.delayed(const Duration(seconds: 1), () {
      if (_isLoading && mounted) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds < 10) {
            _loadingMessage = "Analyzing your preferences...";
          } else if (_elapsedSeconds < 20) {
            _loadingMessage = "Creating personalized structure...";
          } else if (_elapsedSeconds < 30) {
            _loadingMessage = "Generating lessons and content...";
          } else {
            _loadingMessage = "Finalizing your course...";
          }
        });
        _startLoadingTimer();
      }
    });
  }

  Future<void> _pickDocument() async {
    setState(() => _isUploadingFile = true);
    
    try {
      Logger.i(_tag, 'Attempting to pick document');
      
      // Check if file picker is available
      if (FilePicker.platform == null) {
        throw Exception('File picker not available on this platform');
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv', 'xlsx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true, // Ensure we get file data
      );

      if (result != null && result.files.isNotEmpty) {
        final selectedFile = result.files.first;
        
        // Check if we have file bytes or path
        Uint8List? bytes;
        if (selectedFile.bytes != null) {
          bytes = selectedFile.bytes!;
        } else if (selectedFile.path != null) {
          final file = File(selectedFile.path!);
          bytes = await file.readAsBytes();
        } else {
          throw Exception('Unable to read file data');
        }
        
        final base64String = base64Encode(bytes);
        
        setState(() {
          _selectedFile = selectedFile;
          _documentBase64 = base64String;
        });
        
        Logger.i(_tag, 'Document selected successfully: ${selectedFile.name} (${bytes.length} bytes)');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${selectedFile.name}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        Logger.i(_tag, 'No file selected by user');
      }
    } catch (e) {
      Logger.e(_tag, 'Error picking document', error: e);
      
      String errorMessage = 'Error selecting file';
      if (e.toString().contains('LateInitializationError')) {
        errorMessage = 'File picker not ready. Please restart the app and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please allow file access in settings.';
      } else if (e.toString().contains('platform')) {
        errorMessage = 'File picker not supported on this device.';
      } else {
        errorMessage = 'Error selecting file: ${e.toString()}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  Future<void> _generateCourse() async {
    if (_selectedPath == 'scratch' && _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }
    
    if (_selectedPath == 'document' && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _elapsedSeconds = 0;
      _loadingMessage = "Analyzing your preferences...";
    });

    _startLoadingTimer();

    try {
      Logger.i(_tag, 'Starting course generation for path: $_selectedPath');

      late dynamic course;
      
      if (_selectedPath == 'scratch') {
        course = await _apiService.generateCoursePlan(
          topic: _topicController.text,
          timeline: _generateTimelineString(),
          difficulty: _generateDifficultyString(),
          customInstructions: _generateCustomInstructions(),
        );
      } else {
        final fileExtension = _selectedFile!.extension ?? 'pdf';
        course = await _apiService.generateCoursePlanFromDocument(
          topic: _topicController.text.isEmpty ? 'Document Analysis' : _topicController.text,
          timeline: _generateTimelineString(),
          difficulty: _generateDifficultyString(),
          customInstructions: _generateCustomInstructions(),
          documentType: fileExtension,
          documentContent: _documentBase64!,
        );
      }

      Logger.i(_tag, 'Course generation completed successfully');

      if (mounted) {
        _loadingController.stop();
        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsScreen(courseId: course.courseID),
          ),
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Course generation failed', error: e);

      if (mounted) {
        _loadingController.stop();
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate course. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(6, (index) {
          bool isActive = index <= _currentStep;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOptionCard({
    required String id,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPathSelectionStep();
      case 1:
        return _buildTopicAndGoalStep();
      case 2:
        return _buildTimeAssessmentStep();
      case 3:
        return _buildExperienceAndStyleStep();
      case 4:
        return _buildPreferencesStep();
      case 5:
        return _buildReviewStep();
      default:
        return _buildPathSelectionStep();
    }
  }

  Widget _buildPathSelectionStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to create your course?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the method that works best for you',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        
        _buildOptionCard(
          id: 'scratch',
          title: 'Start from Scratch',
          description: 'Tell us what you want to learn and we\'ll create everything for you',
          icon: Icons.auto_awesome,
          isSelected: _selectedPath == 'scratch',
          onTap: () => setState(() => _selectedPath = 'scratch'),
        ),
        
        _buildOptionCard(
          id: 'document',
          title: 'Upload Your Content',
          description: 'Have documents, PDFs, or notes? We\'ll turn them into a structured course',
          icon: Icons.upload_file,
          isSelected: _selectedPath == 'document',
          onTap: () => setState(() => _selectedPath = 'document'),
        ),
      ],
    );
  }

  Widget _buildTopicAndGoalStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPath == 'document') ...[
          Text(
            'Upload Your Document',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We support PDF, Word, Excel, images, and more',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: _isUploadingFile ? null : _pickDocument,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: _isUploadingFile
                ? const Center(child: CircularProgressIndicator())
                : _selectedFile != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: colorScheme.primary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFile!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, color: colorScheme.primary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select a file',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'PDF, DOC, XLS, images, etc.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        Text(
          _selectedPath == 'document' 
            ? 'Course Title (Optional)' 
            : 'What do you want to learn?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedPath == 'document'
            ? 'Leave empty to auto-generate from document'
            : 'Enter any topic you\'re interested in',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        if (_selectedPath == 'scratch') ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topicSuggestions.map((topic) => 
              GestureDetector(
                onTap: () => setState(() => _topicController.text = topic),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    topic,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        TextFormField(
          controller: _topicController,
          decoration: InputDecoration(
            labelText: _selectedPath == 'document' ? 'Course Title' : 'Learning Topic',
            hintText: _selectedPath == 'document' 
              ? 'e.g., Advanced Statistics Course'
              : 'e.g., Learning ABCs, Spanish, Cooking, Machine Learning, Art History...',
            prefixIcon: Icon(
              _selectedPath == 'document' ? Icons.title : Icons.lightbulb_outline, 
              color: colorScheme.tertiary
            ),
            filled: true,
            fillColor: colorScheme.surface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        
        if (_selectedPath == 'scratch') ...[
          const SizedBox(height: 32),
          Text(
            'What\'s your main learning goal?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._learningGoals.map((goal) => _buildOptionCard(
            id: goal['id']!,
            title: goal['title']!,
            description: goal['desc']!,
            isSelected: _learningGoal == goal['id'],
            onTap: () => setState(() => _learningGoal = goal['id']!),
          )),
        ],
      ],
    );
  }

  Widget _buildTimeAssessmentStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let\'s plan your learning schedule',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help us create a realistic timeline that fits your life',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'How much time can you dedicate daily?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._dailyTimeOptions.map((option) => _buildOptionCard(
          id: option['id']!,
          title: option['title']!,
          description: option['desc']!,
          isSelected: _dailyTimeCommitment == option['id'],
          onTap: () => setState(() => _dailyTimeCommitment = option['id']!),
        )),
        
        const SizedBox(height: 24),
        
        Text(
          'What\'s your overall timeframe?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickTimeOption('1 week', '1 week'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickTimeOption('2 weeks', '2 weeks'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickTimeOption('1 month', '1 month'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickTimeOption('3 months', '3 months'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickTimeOption('6 months', '6 months'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickTimeOption('Custom', 'custom'),
            ),
          ],
        ),
        
        if (_hasCustomTimeline) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _customTimelineController,
            decoration: InputDecoration(
              labelText: 'Custom Timeline',
              hintText: 'e.g., 2 days, 6 weeks, 4 months, 1 year, summer break...',
              prefixIcon: Icon(Icons.schedule, color: colorScheme.tertiary),
              filled: true,
              fillColor: colorScheme.surface.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickTimeOption(String title, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _totalTimeframe == value;
    final isCustom = value == 'custom';

    return GestureDetector(
      onTap: () {
        setState(() {
          _totalTimeframe = value;
          _hasCustomTimeline = isCustom;
          if (!isCustom) {
            _customTimelineController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceAndStyleStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your background',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us customize the content difficulty and style',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'What\'s your experience with this topic?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._experienceLevels.map((level) => _buildOptionCard(
          id: level['id']!,
          title: level['title']!,
          description: level['desc']!,
          isSelected: _experienceLevel == level['id'],
          onTap: () => setState(() => _experienceLevel = level['id']!),
        )),
        
        const SizedBox(height: 24),
        
        Text(
          'How do you prefer to learn?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        ..._learningStyles.map((style) => _buildOptionCard(
          id: style['id']!,
          title: style['title']!,
          description: style['desc']!,
          isSelected: _learningStyle == style['id'],
          onTap: () => setState(() => _learningStyle = style['id']!),
        )),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any special requirements?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optional: Tell us about your specific needs or preferences',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _customInstructionsController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Special Instructions (Optional)',
            hintText: 'e.g., Use simple words for kids, include lots of quiz questions, focus on practical examples, prepare for SAT exam, avoid complex formulas, make it entertaining with flashcards...',
            prefixIcon: Icon(Icons.notes, color: colorScheme.tertiary),
            filled: true,
            fillColor: colorScheme.surface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Quick preference chips
        Text(
          'Common preferences:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPreferenceChip('Use simple language'),
            _buildPreferenceChip('Focus on practical examples'),
            _buildPreferenceChip('Include plenty of quiz questions'),
            _buildPreferenceChip('Make it fun and engaging'),
            _buildPreferenceChip('Step-by-step explanations'),
            _buildPreferenceChip('Include lots of flashcards'),
            _buildPreferenceChip('Avoid heavy theory'),
            _buildPreferenceChip('Include real-world case studies'),
            _buildPreferenceChip('Short, digestible lessons'),
            _buildPreferenceChip('Prepare for certification'),
            _buildPreferenceChip('Include historical context'),
            _buildPreferenceChip('Focus on current trends'),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceChip(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: () {
        final currentText = _customInstructionsController.text;
        if (currentText.isEmpty) {
          _customInstructionsController.text = text;
        } else if (!currentText.contains(text)) {
          _customInstructionsController.text = '$currentText, $text';
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your course plan',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everything looks good? Let\'s create your personalized course!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewItem('Course Type', 
                _selectedPath == 'scratch' ? 'Created from scratch' : 'Based on uploaded document'),
              
              if (_selectedPath == 'document' && _selectedFile != null)
                _buildReviewItem('Document', _selectedFile!.name),
              
              _buildReviewItem('Topic', _topicController.text.isEmpty ? 'Auto-generated' : _topicController.text),
              
              if (_learningGoal.isNotEmpty)
                _buildReviewItem('Learning Goal', 
                  _learningGoals.firstWhere((g) => g['id'] == _learningGoal)['title'] ?? ''),
              
              if (_experienceLevel.isNotEmpty)
                _buildReviewItem('Experience Level', 
                  _experienceLevels.firstWhere((e) => e['id'] == _experienceLevel)['title'] ?? ''),
              
              if (_learningStyle.isNotEmpty)
                _buildReviewItem('Learning Style', 
                  _learningStyles.firstWhere((s) => s['id'] == _learningStyle)['title'] ?? ''),
              
              if (_dailyTimeCommitment.isNotEmpty)
                _buildReviewItem('Daily Time', 
                  _dailyTimeOptions.firstWhere((t) => t['id'] == _dailyTimeCommitment)['title'] ?? ''),
              
              if (_totalTimeframe.isNotEmpty)
                _buildReviewItem('Timeline', _generateTimelineString()),
              
              if (_customInstructionsController.text.isNotEmpty)
                _buildReviewItem('Special Instructions', _customInstructionsController.text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface.withOpacity(0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _loadingAnimation.value * 2.0 * 3.14159,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Creating Your Course',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadingMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                backgroundColor: colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'This usually takes 20-30 seconds',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              if (_elapsedSeconds > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Almost there! Just a few more seconds...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _getNextButtonAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentStep == 5) ...[
                    // Generate Course - icon first for primary action
                    Icon(_getNextButtonIcon(), size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _getNextButtonText(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  if (_currentStep < 5) ...[
                    // Continue - icon after for directional flow
                    const SizedBox(width: 8),
                    Icon(_getNextButtonIcon(), size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    if (_isLoading) return null;
    
    switch (_currentStep) {
      case 0:
        return _selectedPath.isNotEmpty ? _nextStep : null;
      case 1:
        if (_selectedPath == 'document') {
          return _selectedFile != null ? _nextStep : null;
        } else {
          return _topicController.text.isNotEmpty ? _nextStep : null;
        }
      case 2:
        return _dailyTimeCommitment.isNotEmpty && _totalTimeframe.isNotEmpty ? _nextStep : null;
      case 3:
        return _experienceLevel.isNotEmpty && _learningStyle.isNotEmpty ? _nextStep : null;
      case 4:
        return _nextStep;
      case 5:
        return _generateCourse;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 5:
        return 'Generate Course';
      default:
        return 'Continue';
    }
  }

  IconData _getNextButtonIcon() {
    switch (_currentStep) {
      case 5:
        return Icons.auto_awesome;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Welcome! Let\'s Get Started';
      case 1:
        return _selectedPath == 'document' ? 'Upload & Title' : 'Topic & Goals';
      case 2:
        return 'Time Planning';
      case 3:
        return 'Learning Style';
      case 4:
        return 'Preferences';
      case 5:
        return 'Ready to Create';
      default:
        return 'Create Course';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.bodyBackground,
      appBar: CustomAppBar(
        title: _getStepTitle(),
        leading: _currentStep > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
            )
          : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Step indicator
              _buildStepIndicator(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(),
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}
