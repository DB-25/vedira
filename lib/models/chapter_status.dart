class ChapterStatus {
  final String lessonsStatus;
  final String mcqsStatus;
  final String flashcardsStatus;
  final DateTime lastUpdated;

  ChapterStatus({
    required this.lessonsStatus,
    required this.mcqsStatus,
    required this.flashcardsStatus,
    required this.lastUpdated,
  });

  factory ChapterStatus.fromJson(Map<String, dynamic> json) {
    return ChapterStatus(
      lessonsStatus: json['lessons_status']?.toString() ?? 'PENDING',
      mcqsStatus: json['mcqs_status']?.toString() ?? 'PENDING',
      flashcardsStatus: json['flashcards_status']?.toString() ?? 'PENDING',
      lastUpdated:
          DateTime.tryParse(json['last_updated']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessons_status': lessonsStatus,
      'mcqs_status': mcqsStatus,
      'flashcards_status': flashcardsStatus,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  // Check if chapter has any content generated
  bool get hasContent => lessonsStatus == 'COMPLETED';

  // Check if MCQs are available
  bool get hasMcqs => mcqsStatus == 'COMPLETED';

  // Check if flashcards are available
  bool get hasFlashcards => flashcardsStatus == 'COMPLETED';

  // Check if anything is currently generating
  bool get isGenerating =>
      lessonsStatus == 'GENERATING' || mcqsStatus == 'GENERATING' || flashcardsStatus == 'GENERATING';

  // Check if anything has failed
  bool get hasFailed => lessonsStatus == 'FAILED' || mcqsStatus == 'FAILED' || flashcardsStatus == 'FAILED';

  // Create a copy with updated fields
  ChapterStatus copyWith({
    String? lessonsStatus,
    String? mcqsStatus,
    String? flashcardsStatus,
    DateTime? lastUpdated,
  }) {
    return ChapterStatus(
      lessonsStatus: lessonsStatus ?? this.lessonsStatus,
      mcqsStatus: mcqsStatus ?? this.mcqsStatus,
      flashcardsStatus: flashcardsStatus ?? this.flashcardsStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
