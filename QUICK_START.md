# Quick Start Guide

## Prerequisites

1. **Install Flutter SDK** (>=3.0.0)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Install IDE**
   - VS Code with Flutter extension, OR
   - Android Studio with Flutter plugin

3. **Platform-specific setup**
   - **iOS**: Xcode (macOS only)
   - **Android**: Android Studio with Android SDK
   - **Web**: Chrome browser
   - **Desktop**: Platform-specific tools

## Initial Setup

### 1. Install Dependencies

```bash
cd Coach-dashboard-flutter
flutter pub get
```

### 2. Generate Code

This project uses code generation for models and API clients:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run

# Run on web
flutter run -d chrome

# Run on desktop
flutter run -d macos  # or windows, linux
```

## Project Structure Overview

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App constants
│   ├── models/             # Shared data models
│   ├── services/           # Core services (API, Auth, etc.)
│   ├── theme/              # App theming
│   └── utils/              # Utility functions
│
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── coach/             # Coach features
│   │   ├── workouts/
│   │   ├── meal_plans/
│   │   ├── clients/
│   │   └── analytics/
│   └── client/            # Client features
│       ├── workout_tracking/
│       ├── water_tracking/
│       ├── step_tracking/
│       ├── meal_plans/
│       └── progress/
│
└── main.dart              # App entry point
```

## Key Features to Implement

### Phase 1: Foundation
1. ✅ Project structure (Done)
2. ⏳ Authentication system
3. ⏳ Navigation setup
4. ⏳ Theme configuration

### Phase 2: Coach Features
1. ⏳ Workout management
2. ⏳ Meal plan management
3. ⏳ Client management

### Phase 3: Client Features
1. ⏳ Workout tracking
2. ⏳ Water tracking
3. ⏳ Step tracking
4. ⏳ Progress tracking

## Next Steps

1. **Set up backend** (Firebase or custom)
   - See `IMPLEMENTATION_GUIDE.md` for details

2. **Start with authentication**
   - Create login/register screens
   - Implement auth service
   - Set up role-based routing

3. **Build core features incrementally**
   - Follow the implementation guide
   - Test each feature before moving on

## Useful Commands

```bash
# Clean build
flutter clean
flutter pub get

# Run tests
flutter test

# Build for production
flutter build apk --release          # Android
flutter build ios --release          # iOS
flutter build web --release          # Web
flutter build macos --release        # macOS

# Code generation (watch mode)
flutter pub run build_runner watch

# Analyze code
flutter analyze

# Format code
flutter format .
```

## Troubleshooting

### Code generation issues
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Platform-specific issues
- Check `IMPLEMENTATION_GUIDE.md` for platform setup
- Verify platform-specific dependencies
- Check platform configuration files

### Build errors
- Run `flutter doctor` to check setup
- Verify all dependencies are installed
- Check platform-specific requirements

## Documentation

- **ARCHITECTURE.md** - Detailed architecture documentation
- **FEATURES.md** - Complete feature list and roadmap
- **IMPLEMENTATION_GUIDE.md** - Step-by-step implementation guide
- **README.md** - Project overview

## Getting Help

1. Check the documentation files
2. Review Flutter documentation: https://flutter.dev/docs
3. Check package documentation on pub.dev
4. Review example code in the project

## Development Tips

1. **Use code generation**: Run `build_runner watch` during development
2. **Test frequently**: Write tests as you build features
3. **Follow architecture**: Keep features organized in the feature folder
4. **Use state management**: Leverage Riverpod for state management
5. **Platform testing**: Test on multiple platforms regularly

Happy coding! 🚀


