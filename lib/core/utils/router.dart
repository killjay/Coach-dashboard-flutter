import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../models/workout.dart';
import '../models/meal_plan.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/coach/presentation/screens/coach_dashboard_screen.dart';
import '../../features/client/presentation/screens/client_dashboard_screen.dart';
import '../../features/coach/workouts/presentation/screens/workout_list_screen.dart';
import '../../features/coach/workouts/presentation/screens/create_workout_screen.dart';
import '../../features/coach/workouts/presentation/screens/workout_detail_screen.dart';
import '../../features/coach/meal_plans/presentation/screens/ingredient_list_screen.dart';
import '../../features/coach/meal_plans/presentation/screens/create_ingredient_screen.dart';
import '../../features/coach/meal_plans/presentation/screens/cooking_video_list_screen.dart';
import '../../features/coach/meal_plans/presentation/screens/create_cooking_video_screen.dart';
import '../../features/coach/meal_plans/presentation/screens/cooking_video_detail_screen.dart';
import '../../features/coach/clients/presentation/screens/client_list_screen.dart';
import '../../features/coach/clients/presentation/screens/client_detail_screen.dart';
import '../../features/coach/clients/presentation/screens/add_client_screen.dart';
import '../../features/client/workout_tracking/presentation/screens/workout_tracking_screen.dart';
import '../../features/client/workout_tracking/presentation/screens/workout_execution_screen.dart';
import '../../features/client/water_tracking/presentation/screens/water_tracking_screen.dart';
import '../../features/client/progress/presentation/screens/progress_screen.dart';
import '../../features/coach/invoices/presentation/screens/invoice_list_screen.dart';
import '../../features/coach/invoices/presentation/screens/create_invoice_screen.dart';
import '../../features/coach/invoices/presentation/screens/invoice_detail_screen.dart';
import '../../features/coach/analytics/presentation/screens/analytics_screen.dart';
import '../../core/models/invoice.dart';
import '../../core/models/goal.dart';
import '../../features/shared/messaging/presentation/screens/conversation_list_screen.dart';
import '../../features/shared/messaging/presentation/screens/chat_screen.dart';
import '../../core/models/message.dart';
import '../../features/coach/meal_plans/presentation/screens/assign_meal_plan_screen.dart';
import '../../features/shared/notifications/presentation/screens/notifications_screen.dart';
import '../../features/coach/workouts/presentation/screens/workout_calendar_screen.dart';
import '../../features/shared/messaging/presentation/screens/client_conversation_list_screen.dart';
import '../../features/client/meal_plans/presentation/screens/assigned_meal_plans_screen.dart';
import '../../features/client/workouts/presentation/screens/client_workout_calendar_screen.dart';
import '../../features/coach/goals/presentation/screens/goal_list_screen.dart';
import '../../features/coach/goals/presentation/screens/create_goal_screen.dart';
import '../../features/coach/goals/presentation/screens/goal_detail_screen.dart';
import '../../features/client/goals/presentation/screens/client_goals_screen.dart';
import '../../features/client/goals/presentation/screens/client_goal_detail_screen.dart';

/// App routes
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String coachDashboard = '/coach';
  static const String clientDashboard = '/client';
  static const String coachWorkouts = '/coach/workouts';
  static const String createWorkout = '/coach/workouts/create';
  static const String workoutDetail = '/coach/workouts/:id';
  static const String ingredients = '/coach/meal-plans/ingredients';
  static const String createIngredient = '/coach/meal-plans/ingredients/create';
  static const String cookingVideos = '/coach/meal-plans/videos';
  static const String createCookingVideo = '/coach/meal-plans/videos/create';
  static const String cookingVideoDetail = '/coach/meal-plans/videos/:id';
  static const String clients = '/coach/clients';
  static const String addClient = '/coach/clients/add';
  static const String clientDetail = '/coach/clients/:id';
  static const String clientWorkouts = '/client/workouts';
  static const String clientWater = '/client/water';
  static const String clientProgress = '/client/progress';
  static const String clientMessages = '/client/messages';
  static const String clientMealPlans = '/client/meal-plans';
  static const String clientNotifications = '/client/notifications';
  static const String clientWorkoutCalendar = '/client/workouts/calendar';
  static const String clientWorkoutExecute = '/client/workouts/execute';
  static const String invoices = '/coach/invoices';
  static const String createInvoice = '/coach/invoices/create';
  static const String invoiceDetail = '/coach/invoices/:id';
  static const String analytics = '/coach/analytics';
  static const String messages = '/messages';
  static const String chat = '/messages/:clientId';
  static const String assignMealPlan = '/coach/meal-plans/assign';
  static const String notifications = '/notifications';
  static const String workoutCalendar = '/coach/workouts/calendar';
  static const String coachGoals = '/coach/goals';
  static const String createGoal = '/coach/goals/create';
  static const String goalDetail = '/coach/goals/:id';
  static const String clientGoals = '/client/goals';
  static const String clientGoalDetail = '/client/goals/:id';
}

/// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // Skip authentication checks if disabled in config
      if (AppConfig.skipAuthentication) {
        // Allow direct access to dashboards
        if (state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register) {
          // Redirect from login/register to default dashboard
          return AppConfig.defaultRole == 'coach'
              ? AppRoutes.coachDashboard
              : AppRoutes.clientDashboard;
        }
        return null; // No redirect needed
      }

      // Normal authentication flow (when skipAuthentication is false)
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // If not authenticated and not on login/register, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.login;
      }

      // If authenticated and on login/register, redirect to appropriate dashboard
      if (isAuthenticated && isLoggingIn) {
        final user = authState.value;
        if (user?.role == 'coach') {
          return AppRoutes.coachDashboard;
        } else {
          return AppRoutes.clientDashboard;
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachDashboard,
        builder: (context, state) => const CoachDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientDashboard,
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachWorkouts,
        builder: (context, state) => const WorkoutListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createWorkout,
        builder: (context, state) {
          final workout = state.extra as Workout?;
          return CreateWorkoutScreen(workout: workout);
        },
      ),
      GoRoute(
        path: AppRoutes.workoutDetail,
        builder: (context, state) {
          final workoutId = state.pathParameters['id']!;
          return WorkoutDetailScreen(workoutId: workoutId);
        },
      ),
      GoRoute(
        path: AppRoutes.ingredients,
        builder: (context, state) => const IngredientListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createIngredient,
        builder: (context, state) {
          final ingredient = state.extra as Ingredient?;
          return CreateIngredientScreen(ingredient: ingredient);
        },
      ),
      GoRoute(
        path: AppRoutes.cookingVideos,
        builder: (context, state) => const CookingVideoListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createCookingVideo,
        builder: (context, state) {
          final video = state.extra as CookingVideo?;
          return CreateCookingVideoScreen(video: video);
        },
      ),
      GoRoute(
        path: AppRoutes.cookingVideoDetail,
        builder: (context, state) {
          final videoId = state.pathParameters['id']!;
          return CookingVideoDetailScreen(videoId: videoId);
        },
      ),
      GoRoute(
        path: AppRoutes.clients,
        builder: (context, state) => const ClientListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addClient,
        builder: (context, state) => const AddClientScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientDetail,
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          return ClientDetailScreen(clientId: clientId);
        },
      ),
      GoRoute(
        path: AppRoutes.clientWorkouts,
        builder: (context, state) => const WorkoutTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientWorkoutExecute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final workoutId = extra?['workoutId'] as String? ?? '';
          final assignmentId = extra?['assignmentId'] as String? ?? '';
          return WorkoutExecutionScreen(
            workoutId: workoutId,
            assignmentId: assignmentId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.clientWater,
        builder: (context, state) => const WaterTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientProgress,
        builder: (context, state) => const ProgressScreen(),
      ),
      // Invoice routes
      GoRoute(
        path: AppRoutes.invoices,
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createInvoice,
        builder: (context, state) {
          final invoice = state.extra as Invoice?;
          final clientId = state.uri.queryParameters['clientId'];
          return CreateInvoiceScreen(
            invoice: invoice,
            clientId: clientId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.invoiceDetail,
        builder: (context, state) {
          final invoiceId = state.pathParameters['id']!;
          return InvoiceDetailScreen(invoiceId: invoiceId);
        },
      ),
      // Analytics route
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      // Messaging routes
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const ConversationListScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final conversation = state.extra as Conversation?;
          return ChatScreen(
            clientId: clientId,
            conversation: conversation,
          );
        },
      ),
      // Meal plan assignment route
      GoRoute(
        path: AppRoutes.assignMealPlan,
        builder: (context, state) {
          final clientId = state.uri.queryParameters['clientId'];
          final mealPlanId = state.uri.queryParameters['mealPlanId'];
          return AssignMealPlanScreen(
            clientId: clientId,
            mealPlanId: mealPlanId,
          );
        },
      ),
      // Notifications route
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // Workout calendar route
      GoRoute(
        path: AppRoutes.workoutCalendar,
        builder: (context, state) => const WorkoutCalendarScreen(),
      ),
      // Client routes
      GoRoute(
        path: AppRoutes.clientMessages,
        builder: (context, state) => const ClientConversationListScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientMealPlans,
        builder: (context, state) => const AssignedMealPlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientNotifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientWorkoutCalendar,
        builder: (context, state) => const ClientWorkoutCalendarScreen(),
      ),
      // Goal routes
      GoRoute(
        path: AppRoutes.coachGoals,
        builder: (context, state) => const GoalListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createGoal,
        builder: (context, state) {
          final goal = state.extra as Goal?;
          final clientId = state.uri.queryParameters['clientId'];
          return CreateGoalScreen(
            goal: goal,
            clientId: clientId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.goalDetail,
        builder: (context, state) {
          final goalId = state.pathParameters['id']!;
          return GoalDetailScreen(goalId: goalId);
        },
      ),
      GoRoute(
        path: AppRoutes.clientGoals,
        builder: (context, state) => const ClientGoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientGoalDetail,
        builder: (context, state) {
          final goalId = state.pathParameters['id']!;
          return ClientGoalDetailScreen(goalId: goalId);
        },
      ),
    ],
  );
});

