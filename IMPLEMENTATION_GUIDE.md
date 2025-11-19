# Implementation Guide

## Getting Started

### 1. Install Flutter

If you haven't already, install Flutter SDK:
- Visit: https://flutter.dev/docs/get-started/install
- Follow platform-specific installation instructions

### 2. Initialize the Project

```bash
cd Coach-dashboard-flutter
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Set Up Backend

Choose one of the following backend options:

#### Option A: Firebase (Recommended for Quick Start)
1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password, Google, Apple)
3. Create Firestore database
4. Enable Cloud Storage for images/videos
5. Add Firebase configuration files:
   - `ios/Runner/GoogleService-Info.plist` (iOS)
   - `android/app/google-services.json` (Android)
   - Web configuration in `index.html`

#### Option B: Custom Backend
1. Set up your backend API (Node.js, Python, etc.)
2. Configure API endpoints in `lib/core/constants/app_constants.dart`
3. Implement API service in `lib/core/services/api_service.dart`

### 4. Platform-Specific Setup

#### iOS Setup
1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing and capabilities
3. Add HealthKit capability for step tracking
4. Add camera permission for progress photos

#### Android Setup
1. Configure `android/app/build.gradle`
2. Add permissions in `android/app/src/main/AndroidManifest.xml`:
   - Health data permissions
   - Camera permission
   - Internet permission

#### Web Setup
1. Configure `web/index.html`
2. Set up Firebase (if using)
3. Configure CORS if using custom backend

## Development Workflow

### Phase 1: Foundation (Week 1-2)

#### 1.1 Authentication System
- [ ] Set up authentication service
- [ ] Create login/register screens
- [ ] Implement role-based routing
- [ ] Add profile setup flow

**Files to create:**
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`
- `lib/core/services/auth_service.dart`

#### 1.2 Core Services
- [ ] API service setup
- [ ] Local storage service
- [ ] Navigation setup (GoRouter)
- [ ] Theme configuration

**Files to create:**
- `lib/core/services/api_service.dart`
- `lib/core/services/storage_service.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/utils/router.dart`

### Phase 2: Coach Features (Week 3-4)

#### 2.1 Workout Management
- [ ] Workout list screen
- [ ] Create/edit workout screen
- [ ] Exercise library
- [ ] Workout assignment to clients

**Files to create:**
- `lib/features/coach/workouts/presentation/screens/workout_list_screen.dart`
- `lib/features/coach/workouts/presentation/screens/create_workout_screen.dart`
- `lib/features/coach/workouts/data/repositories/workout_repository.dart`

#### 2.2 Meal Plan Management
- [ ] Meal plan list screen
- [ ] Create/edit meal plan screen
- [ ] Recipe management
- [ ] Meal plan assignment

**Files to create:**
- `lib/features/coach/meal_plans/presentation/screens/meal_plan_list_screen.dart`
- `lib/features/coach/meal_plans/presentation/screens/create_meal_plan_screen.dart`

#### 2.3 Client Management
- [ ] Client list screen
- [ ] Client profile screen
- [ ] Client progress view

**Files to create:**
- `lib/features/coach/clients/presentation/screens/client_list_screen.dart`
- `lib/features/coach/clients/presentation/screens/client_profile_screen.dart`

### Phase 3: Client Features (Week 5-6)

#### 3.1 Workout Tracking
- [ ] Assigned workouts list
- [ ] Workout detail screen
- [ ] Workout logging
- [ ] Workout history

**Files to create:**
- `lib/features/client/workout_tracking/presentation/screens/workout_list_screen.dart`
- `lib/features/client/workout_tracking/presentation/screens/workout_detail_screen.dart`

#### 3.2 Water Tracking
- [ ] Water intake screen
- [ ] Daily water log
- [ ] Water statistics

**Files to create:**
- `lib/features/client/water_tracking/presentation/screens/water_tracking_screen.dart`
- `lib/features/client/water_tracking/data/repositories/water_repository.dart`

#### 3.3 Step Tracking
- [ ] Step counter screen
- [ ] Health data integration
- [ ] Step statistics

**Files to create:**
- `lib/features/client/step_tracking/presentation/screens/step_tracking_screen.dart`
- `lib/features/client/step_tracking/data/repositories/step_repository.dart`
- `lib/core/services/health_service.dart`

#### 3.4 Meal Plan Viewing
- [ ] Assigned meal plans
- [ ] Meal plan detail
- [ ] Recipe viewer

**Files to create:**
- `lib/features/client/meal_plans/presentation/screens/meal_plan_list_screen.dart`
- `lib/features/client/meal_plans/presentation/screens/meal_plan_detail_screen.dart`

### Phase 4: Integration & Polish (Week 7-8)

#### 4.1 Backend Integration
- [ ] Connect all features to backend
- [ ] Implement data synchronization
- [ ] Add offline support
- [ ] Error handling

#### 4.2 Real-time Updates
- [ ] Push notifications
- [ ] Real-time data sync
- [ ] Activity feeds

#### 4.3 Testing
- [ ] Unit tests
- [ ] Widget tests
- [ ] Integration tests

## Code Generation

After creating models with `@freezed` and `@JsonSerializable`, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For watch mode (auto-regenerate on changes):

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## State Management Pattern

### Using Riverpod

```dart
// Provider definition
final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier(ref.read(workoutRepositoryProvider));
});

// Usage in widget
final workoutState = ref.watch(workoutProvider);
```

## API Integration Pattern

### Using Dio + Retrofit

```dart
@RestApi()
abstract class WorkoutApi {
  factory WorkoutApi(Dio dio) = _WorkoutApi;
  
  @GET('/workouts')
  Future<List<Workout>> getWorkouts();
  
  @POST('/workouts')
  Future<Workout> createWorkout(@Body() Workout workout);
}
```

## Health Data Integration

### iOS (HealthKit)
1. Add HealthKit capability in Xcode
2. Request permissions:
```dart
await Health().requestAuthorization([HealthDataType.STEPS]);
```
3. Read step data:
```dart
final steps = await Health().getHealthDataFromTypes(
  DateTime.now().subtract(Duration(days: 1)),
  DateTime.now(),
  [HealthDataType.STEPS],
);
```

### Android (Google Fit)
1. Add Google Fit API dependency
2. Request permissions
3. Read step data from Google Fit

## Testing Strategy

### Unit Tests
Test business logic in repositories and use cases:
```dart
test('should return workout list', () async {
  // Arrange
  // Act
  // Assert
});
```

### Widget Tests
Test UI components:
```dart
testWidgets('should display workout list', (tester) async {
  // Build widget
  // Find widgets
  // Verify
});
```

### Integration Tests
Test complete user flows:
```dart
testWidgets('complete workout flow', (tester) async {
  // Navigate through app
  // Interact with widgets
  // Verify results
});
```

## Deployment Checklist

### Before Release
- [ ] All features tested
- [ ] Performance optimized
- [ ] Error handling implemented
- [ ] Analytics integrated
- [ ] Crash reporting set up
- [ ] App icons and splash screens
- [ ] Privacy policy and terms
- [ ] App store listings prepared

### Platform-Specific
- [ ] iOS: App Store Connect setup
- [ ] Android: Google Play Console setup
- [ ] Web: Hosting configured
- [ ] Desktop: Code signing (if needed)

## Common Issues & Solutions

### Issue: Code generation fails
**Solution**: Delete `.dart_tool` and `build` folders, then run:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Health data not working
**Solution**: 
- Check platform-specific permissions
- Verify HealthKit/Google Fit setup
- Test on real device (not simulator)

### Issue: Build errors on specific platform
**Solution**: 
- Check platform-specific dependencies
- Verify platform configuration files
- Clean and rebuild

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Health Package](https://pub.dev/packages/health)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

## Next Steps

1. Set up your development environment
2. Choose and configure your backend
3. Start with Phase 1 (Foundation)
4. Iterate and test frequently
5. Deploy incrementally

Good luck with your development! 🚀


