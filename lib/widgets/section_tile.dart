import 'package:flutter/material.dart';

class SectionTile extends StatelessWidget {
  final String? title;
  final int? lessonCount;

  const SectionTile({super.key, this.title, this.lessonCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title ?? 'Section Title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text('${lessonCount ?? 3} Lessons'),
        ],
      ),
    );
  }
}
