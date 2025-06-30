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

![QR Code for iPhone](https://github.com/user-attachments/assets/38666830-2ae4-4edf-94b1-3a7be3a68a45)


### **Android**
*Scan the QR code below to download apk file for Andriod:*

![Download APK](https://github.com/user-attachments/assets/75979375-e6bf-4be2-9417-b7d418d763f9)


**Note**: For Android installation, you may need to enable "Install from unknown sources" in your device settings.
Steps to Enable Installation from Unknown Sources:
   - Navigate to **Settings > Apps & notifications**.
   - Tap on **Special app access**.
   - Select **Allow Install apps from unknown sources**.

### **Sample Login Credentials**
For testing purposes, you can use the following sample credentials:

**Email**: `light1507041@gmail.com`  
**Password**: `Test@123`

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

## 🏗️ **Architecture**

- **🚀 22 AWS Lambda Functions** - All business logic runs serverlessly
- **🔄 AWS Step Functions** - Orchestrate complex content generation workflows
- **🌐 API Gateway** - RESTful endpoints serving the mobile app
- **🗄️ DynamoDB + S3** - Scalable data storage
- **🤖 AI Integration** - Multi-provider AI content generation

---

## 🛠️ **AWS Services Used**

### **Core Compute & Orchestration**
- **AWS Lambda** (22 functions) - Authentication, course management, AI content generation
- **AWS Step Functions** - Multi-step workflow orchestration
- **API Gateway** - HTTP API endpoints

### **Data & Storage**
- **DynamoDB** (2 tables) - Course plans and flashcards
- **S3** (3 buckets) - Lesson content, questions, course images
- **Cognito** - User authentication and JWT management

### **Infrastructure & Monitoring**
- **AWS CDK** - Infrastructure as Code
- **CloudWatch** - Logging and monitoring
- **IAM** - Security and permissions

### **AI & External Integration**
- **AWS Bedrock** - Claude AI models
- **External AI APIs** - Google AI Studio (Gemini) integration

> **💡 Implementation Details**: All the architecture, AWS services, and backend logic described above are implemented in the **[VEDIRA Backend Repository](https://github.com/rudra-sett/vedira-api)**. The backend codebase contains the complete serverless infrastructure, Lambda functions, and API implementations.

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
