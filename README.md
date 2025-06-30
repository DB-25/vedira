#  VEDIRA - Your Lesson Buddy
## 🚀 **Overview**

**VEDIRA** is a **Flutter cross-platform mobile application** that provides personalized AI-powered learning experiences.This is the frontend of the app and this frontend connects to the [**VEDIRA serverless backend API**](https://github.com/rudra-sett/vedira-api) to deliver custom educational content.

> **🔗 Frontend Repository**: [`vedira`](https://github.com/DB-25/vedira) - This Flutter mobile app (current repository)  
> **🔗 Backend Repository**: [`vedira-api`](https://github.com/rudra-sett/vedira-api) - Serverless AWS Lambda backend

---

## 📱 **Download the App**

### **iOS (iPhone/iPad)**
Download VEDIRA on iOS through TestFlight:

**TestFlight Link**: [Download on TestFlight](your-testflight-invite-link)

*Scan the QR code below to download on iOS:*
```
[QR CODE FOR iOS TESTFLIGHT]
```

### **Android**
Download the APK directly:

**APK Download**: [Download APK](your-apk-download-link)

*Scan the QR code below to download on Android:*
```
[QR CODE FOR ANDROID APK]
```

**Note**: For Android installation, you may need to enable "Install from unknown sources" in your device settings.

---

## ✨ **Features**

- **🎓 Personalized Learning** - AI-generated custom courses tailored to your goals
- **📅 Flexible Scheduling** - Learn at your own pace with structured daily lessons
- **🧠 Interactive Learning** - Quizzes, flashcards, and progress tracking
- **📱 Cross-Platform** - iOS, Android, Web, Windows, macOS, and Linux
- **🔐 Secure Authentication** - Email-based registration with JWT tokens
- **☁️ Cloud-Powered** - Real-time content generation from serverless backend

---

## 🛠️ **Tech Stack**

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **HTTP Client** - API communication with serverless backend
- **Secure Storage** - Local data persistence
- **State Management** - Reactive UI updates

---

## 🚀 **Quick Start**

### **Prerequisites**
- Flutter SDK (latest stable)
- Dart SDK
- Platform development tools (Xcode, Android Studio)

### **Installation**
```bash
git clone https://github.com/DB-25/vedira.git
cd vedira
flutter pub get
flutter run
```

### **Project Structure**
```
lib/
├── screens/          # UI screens and navigation
├── services/         # API communication with backend
├── models/           # Data models matching backend API
├── widgets/          # Reusable UI components
├── controllers/      # Business logic and state management
└── utils/           # Constants and utility functions
```

---

## 🌐 **Backend Integration**

This Flutter app communicates with the **VEDIRA serverless backend** via RESTful APIs:

- **Authentication** - User registration, login, JWT token management
- **Course Management** - Fetch personalized courses and lessons
- **Content Delivery** - Stream AI-generated lessons, quizzes, flashcards
- **Progress Tracking** - Sync learning progress across devices

---

## 📚 **Complete Documentation**

For detailed technical documentation, architecture, and development guides:

**📖 [REPOGUIDE.md](./REPOGUIDE.md)** - Comprehensive technical documentation

---

## 🔗 **Related Repositories**

- **[vedira](https://github.com/DB-25/vedira)** - This Flutter mobile application frontend
- **[vedira-api](https://github.com/rudra-sett/vedira-api)** - Serverless AWS Lambda backend

---

*AI-powered learning app built with Flutter*
