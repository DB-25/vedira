class Lesson {
  final String id;
  final String title;
  final String content;
  final List<String> resources;
  final int order;
  final String sectionId;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.resources,
    required this.order,
    required this.sectionId,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      resources: List<String>.from(json['resources']),
      order: json['order'] as int,
      sectionId: json['sectionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'resources': resources,
      'order': order,
      'sectionId': sectionId,
    };
  }
}
