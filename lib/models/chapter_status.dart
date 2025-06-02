class ChapterStatus {
  final String lessonsStatus;
  final String mcqsStatus;
  final DateTime lastUpdated;

  ChapterStatus({
    required this.lessonsStatus,
    required this.mcqsStatus,
    required this.lastUpdated,
  });

  factory ChapterStatus.fromJson(Map<String, dynamic> json) {
    return ChapterStatus(
      lessonsStatus: json['lessons_status']?.toString() ?? 'PENDING',
      mcqsStatus: json['mcqs_status']?.toString() ?? 'PENDING',
      lastUpdated:
          DateTime.tryParse(json['last_updated']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessons_status': lessonsStatus,
      'mcqs_status': mcqsStatus,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  // Check if chapter has any content generated
  bool get hasContent => lessonsStatus == 'COMPLETED';

  // Check if MCQs are available
  bool get hasMcqs => mcqsStatus == 'COMPLETED';

  // Check if anything is currently generating
  bool get isGenerating =>
      lessonsStatus == 'GENERATING' || mcqsStatus == 'GENERATING';

  // Check if anything has failed
  bool get hasFailed => lessonsStatus == 'FAILED' || mcqsStatus == 'FAILED';

  // Create a copy with updated fields
  ChapterStatus copyWith({
    String? lessonsStatus,
    String? mcqsStatus,
    DateTime? lastUpdated,
  }) {
    return ChapterStatus(
      lessonsStatus: lessonsStatus ?? this.lessonsStatus,
      mcqsStatus: mcqsStatus ?? this.mcqsStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
