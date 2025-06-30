# 📱 VEDIRA Mobile App - Repository Guide

## 🚀 **Flutter-Powered Cross-Platform Architecture**

**VEDIRA** is a **modern cross-platform educational mobile app** built entirely with **Flutter** as the core framework. This Flutter-first architecture provides:

- **Single codebase** for iOS, Android, Web, and Desktop platforms
- **Provider pattern** for scalable state management
- **Material Design 3** with adaptive theming
- **Modular architecture** with clear separation of concerns
- **Secure authentication** with JWT token management
- **Offline-capable** with local data persistence

---

## 🏗️ **Project Overview**

VEDIRA Mobile App is the **frontend client** - a personalized learning companion that creates custom courses tailored to your goals and schedule. This Flutter app connects to the VEDIRA API backend (separate repository: `lesson-buddy-api`) to provide AI-powered educational content including lessons, multiple-choice quizzes, and flashcards. Built with Flutter, it delivers a native experience across all platforms while maintaining a single, maintainable codebase.

> **🔗 Architecture**: This is the **frontend Flutter app** that communicates with the **backend AWS Lambda API** (lesson-buddy-api repository)

### **Why Flutter?**
- **Cross-Platform**: Write once, run anywhere (iOS, Android, Web, Desktop)
- **Performance**: Compiled to native code for optimal performance
- **Rich UI**: Material Design and Cupertino widgets for platform-appropriate UI
- **Hot Reload**: Fast development cycle with instant code changes
- **Growing Ecosystem**: Extensive package ecosystem and Google backing

---

## 📁 **Repository Structure**

```
lesson-buddy/
├── 📂 android/                    # Android-specific configuration
├── 📂 ios/                       # iOS-specific configuration
├── 📂 web/                       # Web-specific configuration
├── 📂 windows/                   # Windows-specific configuration
├── 📂 linux/                     # Linux-specific configuration
├── 📂 macos/                     # macOS-specific configuration
├── 📂 lib/                       # Main application code
│   ├── 📂 assets/                # Static assets (images, fonts)
│   ├── 📂 components/            # Core UI components (app bars, buttons)
│   ├── 📂 configs/               # Configuration files
│   ├── 📂 controllers/           # Business logic controllers
│   ├── 📂 models/                # Data models and DTOs
│   ├── 📂 screens/               # UI screens and pages
│   ├── 📂 services/              # Backend integration services
│   ├── 📂 utils/                 # Utility classes and constants
│   ├── 📂 widgets/               # Reusable UI components
│   └── 📄 main.dart              # App entry point
├── 📂 test/                      # Unit and widget tests
├── 📄 pubspec.yaml               # Dependencies and configuration
├── 📄 analysis_options.yaml      # Linting and analysis rules
└── 📄 README.md                  # Project documentation
```

---

## 🎯 **Core Architecture Patterns**

### **🏛️ Provider Pattern State Management**
The app uses the **Provider pattern** for state management, offering:
- **Reactive UI**: Automatic UI updates when state changes
- **Dependency Injection**: Clean service injection throughout the widget tree
- **Memory Efficient**: Automatic disposal of resources
- **Testable**: Easy mocking and testing of business logic

### **🔧 Service Layer Architecture**
All backend communication is handled through specialized service classes:
- **Separation of Concerns**: UI logic separated from business logic
- **Reusable Components**: Services can be used across multiple screens
- **Error Handling**: Centralized error handling and retry logic
- **Caching Strategy**: Intelligent data caching and synchronization

---

## 📱 **Screens & User Interface (10 Screens)**

### **🔐 Authentication Screens (3 Screens)**
| Screen | Purpose | Key Features | Navigation |
|--------|---------|--------------|-----------|
| `SplashScreen` | App initialization and routing | Logo animation, theme detection, auto-login | Entry point |
| `LoginScreen` | User authentication | Email/password login, signup, forgot password | From splash or after logout |
| `VerificationScreen` | Email verification | OTP input, resend verification, auto-verification | After signup |

### **📚 Course Management Screens (4 Screens)**
| Screen | Purpose | Key Features | Navigation |
|--------|---------|--------------|-----------|
| `HomeScreen` | Course dashboard | Course grid, search, create new course | Main hub |
| `CreateCourseScreen` | Course creation wizard | AI-powered generation, file upload, course settings | From home screen |
| `CourseDetailsScreen` | Course overview and management | Chapter list, progress tracking, course settings | From course selection |
| `LessonViewScreen` | Lesson content viewer | Markdown rendering, progress tracking, navigation | From chapter selection |

### **🎯 Interactive Learning Screens (3 Screens)**
| Screen | Purpose | Key Features | Navigation |
|--------|---------|--------------|-----------|
| `McqQuizScreen` | Multiple-choice quizzes | Question navigation, scoring, results | From lesson or chapter |
| `FlashcardScreen` | Interactive flashcard study | Card flipping, progress tracking, difficulty rating | From lesson or chapter |
| `PrivacyPolicyScreen` | Legal and privacy information | Scrollable content, back navigation | From settings or signup |

---

## 🔧 **Services & Backend Integration (11 Services)**

### **🔐 Authentication Services (2 Services)**
| Service | Purpose | Key Methods | Dependencies |
|---------|---------|-------------|--------------|
| `AuthService` | JWT authentication management | `login()`, `signup()`, `logout()`, `refreshToken()` | SecureStorageService, ApiClient |
| `SecureStorageService` | Secure token storage | `storeToken()`, `getToken()`, `deleteToken()` | flutter_secure_storage |

### **🌐 API Integration Services (3 Services)**
| Service | Purpose | Key Methods | Dependencies |
|---------|---------|-------------|--------------|
| `ApiClient` | HTTP client with auth headers | `get()`, `post()`, `put()`, `delete()` | http, AuthService |
| `ApiService` | High-level API interactions | `getCourses()`, `createCourse()`, `getLessonContent()` | ApiClient |
| `ConnectivityService` | Network connectivity monitoring | `checkConnectivity()`, `onConnectivityChanged` | connectivity_plus |

### **📊 Data Management Services (4 Services)**
| Service | Purpose | Key Methods | Dependencies |
|---------|---------|-------------|--------------|
| `ProgressService` | User progress tracking | `updateProgress()`, `getProgress()`, `syncProgress()` | SharedPreferences, ApiService |
| `StarredCoursesService` | Favorite courses management | `starCourse()`, `unstarCourse()`, `getStarredCourses()` | SharedPreferences |
| `McqService` | Quiz and questions management | `getQuestions()`, `submitAnswers()`, `getResults()` | ApiService |
| `FlashcardService` | Flashcard management | `getFlashcards()`, `markReviewed()`, `getFlashcardProgress()` | ApiService |

### **⚙️ Generation & Processing Services (2 Services)**
| Service | Purpose | Key Methods | Dependencies |
|---------|---------|-------------|--------------|
| `GenerationStrategyService` | Course generation logic | `generateFromText()`, `generateFromFile()`, `validateInput()` | ApiService |
| `ChapterGenerationService` | Chapter content processing | `generateChapter()`, `checkStatus()`, `monitorProgress()` | ApiService |

---

## 📦 **Data Models & DTOs (9 Models)**

### **📚 Course-Related Models (4 Models)**
| Model | Purpose | Key Properties | Usage |
|-------|---------|----------------|-------|
| `Course` | Course data structure | `id`, `title`, `description`, `chapters`, `imageUrl` | Course listings, details |
| `Chapter` | Chapter information | `id`, `title`, `lessons`, `status`, `progress` | Course navigation |
| `Lesson` | Individual lesson data | `id`, `title`, `content`, `duration`, `completed` | Lesson viewer |
| `Section` | Lesson content sections | `id`, `type`, `content`, `order` | Content rendering |

### **🎯 Interactive Content Models (3 Models)**
| Model | Purpose | Key Properties | Usage |
|-------|---------|----------------|-------|
| `McqQuestion` | Quiz question structure | `id`, `question`, `options`, `correctAnswer`, `explanation` | Quiz screens |
| `Flashcard` | Flashcard data structure | `id`, `question`, `answer`, `difficulty`, `lastReviewed` | Flashcard study |
| `LessonPlan` | Course structure planning | `title`, `description`, `chapters`, `estimatedHours` | Course creation |

### **📊 Progress & Status Models (2 Models)**
| Model | Purpose | Key Properties | Usage |
|-------|---------|----------------|-------|
| `UserProgress` | User learning progress | `courseId`, `chapterId`, `lessonId`, `progress`, `timeSpent` | Progress tracking |
| `ChapterStatus` | Chapter generation status | `id`, `lessonsStatus`, `mcqsStatus`, `flashcardsStatus` | Generation monitoring |

---

## 🧩 **Reusable Widgets & Components (12 Widgets)**

### **🏗️ Core Components (2 Components)**
| Widget | Purpose | Key Features | Used In |
|--------|---------|--------------|---------|
| `CustomAppBar` | Standardized app bar | Back navigation, title, actions, theming | All screens |
| `CustomButtons` | Consistent button styles | Primary, secondary, loading states | Throughout app |

### **📊 Data Display Widgets (4 Widgets)**
| Widget | Purpose | Key Features | Used In |
|--------|---------|--------------|---------|
| `CourseCard` | Course display component | Image, title, progress, star button | HomeScreen, search results |
| `LessonTile` | Lesson list item | Title, duration, completion status | CourseDetailsScreen |
| `StatusBadge` | Status indicator | Color-coded status, loading states | Throughout app |
| `ReadingProgressIndicator` | Progress visualization | Animated progress bar, percentage | LessonViewScreen |

### **📝 Content Widgets (3 Widgets)**
| Widget | Purpose | Key Features | Used In |
|--------|---------|--------------|---------|
| `CodeBlockBuilder` | Code syntax highlighting | Language detection, copy button | LessonViewScreen |
| `SectionTile` | Content section display | Collapsible, markdown support | LessonViewScreen |
| `AuthenticatedImage` | Secure image loading | Token-based auth, caching | Course images |

### **⚙️ Interactive Widgets (3 Widgets)**
| Widget | Purpose | Key Features | Used In |
|--------|---------|--------------|---------|
| `StudyChapterCard` | Chapter study interface | Progress, actions, status | CourseDetailsScreen |
| `ChapterGenerationProgressDialog` | Generation progress modal | Real-time updates, cancellation | Course creation |
| `ThemeSelector` | Theme switching widget | Light/dark toggle, system theme | Settings |

---

## 🛠️ **Utilities & Configuration (3 Utilities)**

### **📋 Constants & Configuration**
| File | Purpose | Key Contents |
|------|---------|--------------|
| `constants.dart` | App-wide constants | API endpoints, colors, dimensions, text styles |
| `theme_manager.dart` | Theme management | Light/dark themes, color schemes, typography |
| `logger.dart` | Logging system | Debug logging, error tracking, log levels |

---

## 📦 **Key Dependencies**

### **🏗️ Core Framework**
- **flutter**: ^3.2.3 - Core Flutter SDK
- **provider**: ^6.1.1 - State management
- **cupertino_icons**: ^1.0.2 - iOS-style icons

### **🌐 Network & Storage**
- **http**: ^1.1.2 - HTTP client for API calls
- **flutter_secure_storage**: ^9.0.0 - Secure token storage
- **shared_preferences**: ^2.2.2 - Local data persistence
- **connectivity_plus**: ^6.0.5 - Network connectivity monitoring

### **🎨 UI & Content**
- **flutter_markdown**: ^0.6.18+2 - Markdown rendering
- **markdown_widget**: ^2.3.2+8 - Advanced markdown widgets
- **flutter_highlight**: ^0.7.0 - Code syntax highlighting
- **google_fonts**: ^6.1.0 - Typography
- **lottie**: ^3.3.1 - Animations
- **flutter_animate**: ^4.5.2 - UI animations

### **🔧 Utilities**
- **url_launcher**: ^6.2.2 - External URL handling

---

## 🚀 **Getting Started**

### **Prerequisites**
- Flutter SDK 3.2.3 or higher
- Dart SDK (included with Flutter)
- Android Studio / VS Code with Flutter extensions
- iOS development: Xcode (macOS only)

### **Installation**
1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd lesson-buddy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### **Platform-Specific Setup**
- **Android**: Ensure Android SDK is installed and configured
- **iOS**: Requires macOS with Xcode installed
- **Web**: Run with `flutter run -d chrome`
- **Desktop**: Enable desktop support with `flutter config --enable-[platform]-desktop`

---

## 🎯 **Key Features**

### **🔐 Authentication & Security**
- JWT-based authentication with automatic token refresh
- Secure storage for sensitive data
- Automatic logout on token expiration

### **📚 Course Management**
- AI-powered course generation from text or files
- Real-time generation progress tracking
- Offline course content caching

### **🎓 Learning Experience**
- Interactive markdown-based lessons
- Multiple-choice quizzes with instant feedback
- Progress tracking across all content

### **🎨 User Experience**
- Adaptive Material Design 3 theming
- Light/dark mode support
- Smooth animations and transitions
- Cross-platform native performance

---

## 🧪 **Testing**

### **Test Structure**
```
test/
├── 📂 unit/              # Unit tests for services and models
├── 📂 widget/            # Widget tests for UI components
└── 📂 integration/       # Integration tests for complete flows
```

### **Running Tests**
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/auth_service_test.dart
```

---

## 🔧 **Development Guidelines**

### **Code Style**
- Follow official Dart style guide
- Use `analysis_options.yaml` for consistent linting
- Prefer composition over inheritance
- Use meaningful variable and function names

### **State Management**
- Use Provider for app-wide state
- Keep widgets stateless when possible
- Separate business logic from UI code
- Use proper disposal of resources

### **Performance**
- Optimize widget rebuilds with const constructors
- Use ListView.builder for large lists
- Implement proper image caching
- Monitor memory usage and dispose controllers

---

> **💡 Flutter Architecture Benefits:**
> - **Hot Reload**: Instant development feedback
> - **Single Codebase**: Maintain one codebase for all platforms
> - **Native Performance**: Compiled to native ARM code
> - **Rich Ecosystem**: Extensive package repository
> - **Growing Community**: Strong community support and resources 