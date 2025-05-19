class Lesson {
  final String id;
  final String title;
  final String content;
  final List<String> resources;
  final int order;
  final String sectionId;
  final bool completed;
  final bool generated;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.resources,
    required this.order,
    required this.sectionId,
    this.completed = false,
    this.generated = true,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Handle resources field that might be a list of strings or a list of objects with url property
    List<String> parseResources() {
      if (json['resources'] == null) return [];

      try {
        if (json['resources'] is List) {
          return (json['resources'] as List)
              .map((resource) {
                if (resource is String) {
                  return resource;
                } else if (resource is Map && resource.containsKey('url')) {
                  return resource['url'] as String;
                }
                return '';
              })
              .where((url) => url.isNotEmpty)
              .toList();
        }
      } catch (e) {
        print('Error parsing resources: $e');
      }
      return [];
    }

    return Lesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Lesson',
      content: json['content']?.toString() ?? '',
      resources: parseResources(),
      order:
          json['order'] is int
              ? json['order']
              : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      sectionId:
          json['sectionId']?.toString() ?? json['section_id']?.toString() ?? '',
      completed: json['completed'] == true,
      generated: json['generated'] != false, // Default to true if not specified
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
      'completed': completed,
      'generated': generated,
    };
  }

  // Create a copy of this lesson with modified fields
  Lesson copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? resources,
    int? order,
    String? sectionId,
    bool? completed,
    bool? generated,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      resources: resources ?? this.resources,
      order: order ?? this.order,
      sectionId: sectionId ?? this.sectionId,
      completed: completed ?? this.completed,
      generated: generated ?? this.generated,
    );
  }
}
