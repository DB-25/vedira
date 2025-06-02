class McqQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  McqQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];

    // Parse options array
    if (json['options'] != null && json['options'] is List) {
      parsedOptions =
          (json['options'] as List)
              .map((option) => option?.toString() ?? '')
              .where((option) => option.isNotEmpty)
              .toList();
    }

    return McqQuestion(
      question: json['question']?.toString() ?? '',
      options: parsedOptions,
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'answer': answer,
      'explanation': explanation,
    };
  }

  // Get the index of the correct answer in the options list
  int get correctAnswerIndex {
    return options.indexOf(answer);
  }

  // Check if the question is valid (has question, options, and answer)
  bool get isValid {
    return question.isNotEmpty &&
        options.isNotEmpty &&
        answer.isNotEmpty &&
        options.contains(answer);
  }

  // Create a copy with updated fields
  McqQuestion copyWith({
    String? question,
    List<String>? options,
    String? answer,
    String? explanation,
  }) {
    return McqQuestion(
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
    );
  }
}
