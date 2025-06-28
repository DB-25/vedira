class Flashcard {
  final int cardNumber;
  final String question;
  final String answer;
  final DateTime createdAt;

  Flashcard({
    required this.cardNumber,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      cardNumber: json['cardNumber']?.toInt() ?? 0,
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardNumber': cardNumber,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Validation check
  bool get isValid => cardNumber > 0 && question.isNotEmpty && answer.isNotEmpty;

  // Convenience getters for front/back terminology
  String get front => question;
  String get back => answer;

  @override
  String toString() {
    return 'Flashcard{cardNumber: $cardNumber, question: $question, answer: $answer, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Flashcard && runtimeType == other.runtimeType && cardNumber == other.cardNumber;

  @override
  int get hashCode => cardNumber.hashCode;
} 