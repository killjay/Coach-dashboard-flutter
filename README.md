# Coach-Client Fitness Application

A comprehensive cross-platform fitness coaching application built with Flutter, supporting desktop, mobile (iOS/Android), and web platforms.

## 🎯 Overview

This application enables fitness coaches to manage their clients, create and assign workouts and meal plans, while clients can track their workouts, water intake, and step count.

## 📱 Platforms Supported

- ✅ **Desktop**: Windows, macOS, Linux
- ✅ **Mobile**: iOS, Android
- ✅ **Web**: Progressive Web App (PWA)

## 🏗️ Architecture

This project follows a **Clean Architecture** pattern with feature-based organization:

```
lib/
├── core/           # Core utilities, services, and shared code
├── features/       # Feature modules (auth, coach, client)
└── main.dart       # Application entry point
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture documentation.

## ✨ Features

### Coach Dashboard
- Workout creation and management
- Meal plan creation and assignment
- Client management and monitoring
- Analytics and reporting

### Client App
- Workout tracking and logging
- Water intake tracking
- Step count integration (HealthKit/Google Fit)
- Meal plan viewing
- Progress tracking and visualization

See [FEATURES.md](./FEATURES.md) for complete feature list.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (for mobile development)
- VS Code / Android Studio (recommended IDEs)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Coach-dashboard-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run code generation** (for freezed, json_serializable, etc.)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   # For mobile
   flutter run

   # For web
   flutter run -d chrome

   # For desktop
   flutter run -d macos  # or windows, linux
   ```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants
│   ├── theme/          # App theming
│   ├── utils/          # Utility functions
│   ├── services/       # Core services (API, Auth, Storage)
│   └── models/         # Shared models
│
├── features/
│   ├── auth/           # Authentication feature
│   │   ├── data/       # Data layer (repositories, datasources)
│   │   ├── domain/     # Domain layer (entities, use cases)
│   │   └── presentation/ # Presentation layer (screens, widgets)
│   │
│   ├── coach/          # Coach-specific features
│   │   ├── workouts/
│   │   ├── meal_plans/
│   │   ├── clients/
│   │   └── analytics/
│   │
│   ├── client/         # Client-specific features
│   │   ├── workout_tracking/
│   │   ├── water_tracking/
│   │   ├── step_tracking/
│   │   ├── meal_plans/
│   │   └── progress/
│   │
│   └── shared/         # Shared widgets and utilities
│
└── main.dart
```

## 🛠️ Tech Stack

### Frontend
- **Flutter** - UI Framework
- **Riverpod** - State Management
- **GoRouter** - Navigation
- **Hive** - Local Database

### Backend (To be configured)
- Firebase / Custom Backend
- REST API / GraphQL
- Real-time updates

### Key Packages
- `flutter_riverpod` - State management
- `go_router` - Declarative routing
- `dio` - HTTP client
- `health` - Health data integration
- `hive` - Local storage
- `firebase_auth` - Authentication

## 📝 Development Guidelines

### Code Style
- Follow Flutter/Dart style guide
- Use `analysis_options.yaml` for linting
- Write meaningful variable and function names
- Add comments for complex logic

### State Management
- Use Riverpod for state management
- Keep business logic in providers
- Separate UI and business logic

### Testing
- Write unit tests for business logic
- Write widget tests for UI components
- Write integration tests for user flows

## 🔐 Environment Setup

Create a `.env` file (or use environment variables) for:
- API base URL
- Firebase configuration
- API keys
- Other sensitive data

## 📦 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Write/update tests
4. Submit a pull request

## 📄 License

[Add your license here]

## 📞 Support

For issues and questions, please open an issue on GitHub.

## 🗺️ Roadmap

See [FEATURES.md](./FEATURES.md) for detailed feature roadmap and implementation status.

---

**Note**: This is a starter template. Backend integration, Firebase setup, and platform-specific configurations need to be completed based on your requirements.


