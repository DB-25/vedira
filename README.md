# LessonBuddy

A Flutter application for creating and managing educational courses and lessons.

## Features

- Light/dark theme toggle
- Course creation and management
- Lesson organization and viewing
- Modern UI with custom theming

## Getting Started

This project is a Flutter application.

### Prerequisites

- Flutter SDK
- Dart SDK

### Installation

1. Clone the repository

```bash
git clone https://github.com/yourusername/lesson_buddy.git
```

2. Navigate to the project directory

```bash
cd lesson_buddy
```

3. Install dependencies

```bash
flutter pub get
```

4. Run the app

```bash
flutter run
```

## Project Structure

```
LessonBuddyApp
│
├── main.dart
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── course_details_screen.dart
│   ├── lesson_screen.dart
│   └── create_course_screen.dart
├── models/
│   ├── course.dart
│   └── lesson.dart
├── services/
│   └── api_service.dart
├── widgets/
│   ├── course_card.dart
│   ├── section_tile.dart
│   └── lesson_tile.dart
└── utils/
    ├── constants.dart
    └── theme_manager.dart
```
