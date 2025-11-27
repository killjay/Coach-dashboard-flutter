import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/models/meal_plan.dart';
import '../../../../core/models/progress.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/router.dart';
import '../../water_tracking/presentation/screens/water_tracking_screen.dart'
    show dailyWaterProvider;
import '../../../shared/widgets/bottom_nav_bar.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for today's workout assignment with workout details
final todayWorkoutProvider = FutureProvider<({WorkoutAssignment assignment, Workout workout})?>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return null;
  
  final assignments = await workoutRepo.getAssignedWorkouts(user.id);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  
  // Find workout due today or overdue
  for (final assignment in assignments) {
    final dueDate = DateTime(
      assignment.dueDate.year,
      assignment.dueDate.month,
      assignment.dueDate.day,
    );
    if (dueDate.isBefore(todayDate) || dueDate.isAtSameMomentAs(todayDate)) {
      if (assignment.status != 'completed') {
        try {
          final workout = await workoutRepo.getWorkoutById(assignment.workoutId);
          return (assignment: assignment, workout: workout);
        } catch (e) {
          // If workout not found, continue to next assignment
          continue;
        }
      }
    }
  }
  
  return null;
});

/// Provider for today's active meal plan
final todayMealPlanProvider = FutureProvider<MealPlanAssignment?>((ref) async {
  final mealPlanRepo = ref.watch(mealPlanRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return null;
  
  final assignments = await mealPlanRepo.getAssignedMealPlans(user.id);
  final today = DateTime.now();
  
  // Find active meal plan for today
  for (final assignment in assignments) {
    if (assignment.status == 'active' &&
        today.isAfter(assignment.startDate.subtract(const Duration(days: 1))) &&
        today.isBefore(assignment.endDate.add(const Duration(days: 1)))) {
      return assignment;
    }
  }
  
  return null;
});

/// Provider for today's meals (breakfast, lunch, dinner)
final todayMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final assignmentAsync = ref.watch(todayMealPlanProvider);
  
  return assignmentAsync.when(
    data: (assignment) async {
      if (assignment == null) return [];
      
      final mealPlanRepo = ref.watch(mealPlanRepositoryProvider);
      final mealPlan = await mealPlanRepo.getMealPlanById(assignment.mealPlanId);
      return mealPlan.meals;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for weekly workout completion percentage
final weeklyWorkoutCompletionProvider = FutureProvider<double>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return 0.0;
  
  final assignments = await workoutRepo.getAssignedWorkouts(user.id);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  
  int completed = 0;
  int total = 0;
  
  for (final assignment in assignments) {
    final dueDate = assignment.dueDate;
    if (dueDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        dueDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
      total++;
      if (assignment.status == 'completed') {
        completed++;
      }
    }
  }
  
  return total > 0 ? (completed / total) * 100 : 0.0;
});

/// Provider for water goal adherence (last 10 days)
final waterGoalAdherenceProvider = FutureProvider<String>((ref) async {
  final progressRepo = ref.watch(progressRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return '0/10';
  
  const double goal = 2.5; // liters
  final now = DateTime.now();
  int daysMet = 0;
  
  for (int i = 0; i < 10; i++) {
    final date = now.subtract(Duration(days: i));
    final total = await progressRepo.getDailyWaterTotal(user.id, date);
    if (total >= goal) {
      daysMet++;
    }
  }
  
  return '$daysMet/10';
});

/// Provider for upcoming schedule (next 2 events)
final upcomingScheduleProvider = FutureProvider<List<ScheduleItem>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return [];
  
  final assignments = await workoutRepo.getAssignedWorkouts(user.id);
  final now = DateTime.now();
  final items = <ScheduleItem>[];
  
  for (final assignment in assignments) {
    if (assignment.status != 'completed' &&
        assignment.dueDate.isAfter(now.subtract(const Duration(days: 1)))) {
      try {
        final workout = await workoutRepo.getWorkoutById(assignment.workoutId);
        items.add(ScheduleItem(
          title: workout.name,
          date: assignment.dueDate,
          type: 'workout',
        ));
      } catch (e) {
        // Skip if workout not found
        continue;
      }
    }
  }
  
  items.sort((a, b) => a.date.compareTo(b.date));
  return items.take(2).toList();
});

class ScheduleItem {
  final String title;
  final DateTime date;
  final String type; // 'workout', 'meal', 'call'
  
  ScheduleItem({
    required this.title,
    required this.date,
    required this.type,
  });
}

// ============================================================================
// HOME SCREEN
// ============================================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.go(AppRoutes.clientWorkoutCalendar); // Plan
        break;
      case 2:
        context.go(AppRoutes.clientProgress); // Progress
        break;
      case 3:
        context.go(AppRoutes.clientMessages); // Messages
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name?.split(' ').first ?? 'Client';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, userName, isDark, responsive),
            
            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(todayWorkoutProvider);
                  ref.invalidate(todayMealPlanProvider);
                  ref.invalidate(weeklyWorkoutCompletionProvider);
                  ref.invalidate(waterGoalAdherenceProvider);
                  ref.invalidate(upcomingScheduleProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.padding.left,
                    vertical: responsive.spacing(16),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Primary CTA Hero Card
                          _buildHeroCard(context, ref, responsive),
                          SizedBox(height: responsive.spacing(24)),
                          
                          // Daily Habit Quick-Log Tiles
                          _buildQuickLogTiles(context, ref, responsive),
                          SizedBox(height: responsive.spacing(24)),
                          
                          // Progress Rings/Scorecard
                          _buildProgressRings(context, ref, responsive),
                          SizedBox(height: responsive.spacing(24)),
                          
                          // Schedule Preview
                          _buildSchedulePreview(context, ref, responsive),
                          SizedBox(height: responsive.spacing(80)), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName,
    bool isDark,
    Responsive responsive,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.padding.left,
        responsive.spacing(16),
        responsive.padding.right,
        responsive.spacing(12),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $userName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: PhosphorIcon(PhosphorIcons.bell()),
            onPressed: () => context.go(AppRoutes.clientNotifications),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: PhosphorIcon(PhosphorIcons.userCircle()),
            onPressed: () => context.push(AppRoutes.profile),
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    Responsive responsive,
  ) {
    final workoutAsync = ref.watch(todayWorkoutProvider);
    final mealPlanAsync = ref.watch(todayMealPlanProvider);

    return workoutAsync.when(
      data: (workoutData) {
        if (workoutData != null) {
          return _HeroCard(
            title: 'Start Today\'s Workout',
            subtitle: workoutData.workout.name,
            icon: PhosphorIcons.barbell(),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
            ),
            onTap: () {
              context.go(AppRoutes.clientWorkoutExecute);
            },
          );
        }
        
        return mealPlanAsync.when(
          data: (mealPlan) {
            if (mealPlan != null) {
              return _HeroCard(
                title: 'Log Dinner',
                subtitle: 'Complete your meal tracking',
                icon: PhosphorIcons.forkKnife(),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                onTap: () {
                  context.go(AppRoutes.clientMealPlans);
                },
              );
            }
            
            return _HeroCard(
              title: 'Complete Weekly Check-in',
              subtitle: 'Review your progress this week',
              icon: PhosphorIcons.chartLineUp(),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              onTap: () {
                context.go(AppRoutes.clientProgress);
              },
            );
          },
          loading: () => _HeroCard(
            title: 'Loading...',
            subtitle: '',
            icon: PhosphorIcons.hourglass(),
            gradient: const LinearGradient(colors: [Colors.grey, Colors.grey]),
            onTap: null,
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => _HeroCard(
        title: 'Loading...',
        subtitle: '',
        icon: PhosphorIcons.hourglass(),
        gradient: const LinearGradient(colors: [Colors.grey, Colors.grey]),
        onTap: null,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickLogTiles(
    BuildContext context,
    WidgetRef ref,
    Responsive responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Log',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Expanded(
              child: _QuickLogTile(
                icon: PhosphorIcons.drop(),
                label: 'Water',
                color: const Color(0xFF06B6D4),
                onTap: () => _quickLogWater(context, ref),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: _QuickLogTile(
                icon: PhosphorIcons.forkKnife(),
                label: 'Meal',
                color: const Color(0xFFF59E0B),
                onTap: () => context.go(AppRoutes.clientMealPlans),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: _QuickLogTile(
                icon: PhosphorIcons.smiley(),
                label: 'Mood',
                color: const Color(0xFF8B5CF6),
                onTap: () => _showMoodDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _quickLogWater(BuildContext context, WidgetRef ref) {
    final progressRepo = ref.read(progressRepositoryProvider);
    final user = ref.read(currentUserProvider);
    
    if (user == null) return;
    
    // Quick tap - add 250ml (1 glass)
    progressRepo.logWater(clientId: user.id, amount: 0.25).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged 250ml of water'),
            duration: Duration(seconds: 2),
          ),
        );
        ref.invalidate(waterGoalAdherenceProvider);
      }
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showMoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How are you feeling?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoodOption(emoji: '😊', label: 'Great', onTap: () => Navigator.pop(context)),
            _MoodOption(emoji: '😐', label: 'Okay', onTap: () => Navigator.pop(context)),
            _MoodOption(emoji: '😔', label: 'Not Great', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRings(
    BuildContext context,
    WidgetRef ref,
    Responsive responsive,
  ) {
    final workoutCompletion = ref.watch(weeklyWorkoutCompletionProvider);
    final waterAdherence = ref.watch(waterGoalAdherenceProvider);
    final todayWater = ref.watch(dailyWaterProvider(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Row(
          children: [
            Expanded(
              child: workoutCompletion.when(
                data: (percentage) => _ProgressRing(
                  label: 'Workouts',
                  value: percentage,
                  max: 100,
                  unit: '%',
                  color: const Color(0xFF6366F1),
                ),
                loading: () => const _ProgressRing(
                  label: 'Workouts',
                  value: 0,
                  max: 100,
                  unit: '%',
                  color: Colors.grey,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: waterAdherence.when(
                data: (adherence) {
                  final parts = adherence.split('/');
                  final current = int.tryParse(parts[0]) ?? 0;
                  final max = int.tryParse(parts[1]) ?? 10;
                  return _ProgressRing(
                    label: 'Water Goal',
                    value: current.toDouble(),
                    max: max.toDouble(),
                    unit: ' days',
                    color: const Color(0xFF06B6D4),
                  );
                },
                loading: () => const _ProgressRing(
                  label: 'Water Goal',
                  value: 0,
                  max: 10,
                  unit: ' days',
                  color: Colors.grey,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: todayWater.when(
                data: (amount) => _ProgressRing(
                  label: 'Today\'s Water',
                  value: amount,
                  max: 2.5,
                  unit: 'L',
                  color: const Color(0xFF10B981),
                ),
                loading: () => const _ProgressRing(
                  label: 'Today\'s Water',
                  value: 0,
                  max: 2.5,
                  unit: 'L',
                  color: Colors.grey,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSchedulePreview(
    BuildContext context,
    WidgetRef ref,
    Responsive responsive,
  ) {
    final scheduleAsync = ref.watch(upcomingScheduleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: responsive.spacing(12)),
        scheduleAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No upcoming events',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ),
              );
            }
            
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ScheduleCard(item: item);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: PhosphorIcons.house(),
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => _onNavTap(0),
                isDark: isDark,
              ),
              _BottomNavItem(
                icon: PhosphorIcons.calendarCheck(),
                label: 'Plan',
                isActive: _currentIndex == 1,
                onTap: () => _onNavTap(1),
                isDark: isDark,
              ),
              _BottomNavItem(
                icon: PhosphorIcons.chartLineUp(),
                label: 'Progress',
                isActive: _currentIndex == 2,
                onTap: () => _onNavTap(2),
                isDark: isDark,
              ),
              _BottomNavItem(
                icon: PhosphorIcons.chatCircle(),
                label: 'Messages',
                isActive: _currentIndex == 3,
                onTap: () => _onNavTap(3),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET COMPONENTS
// ============================================================================

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PhosphorIcon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                PhosphorIcon(
                  PhosphorIcons.arrowRight(),
                  size: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLogTile extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLogTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String unit;
  final Color color;

  const _ProgressRing({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / max).clamp(0.0, 1.0);
    final displayValue = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 6,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$displayValue$unit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;

  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final isToday = item.date.year == DateTime.now().year &&
        item.date.month == DateTime.now().month &&
        item.date.day == DateTime.now().day;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PhosphorIcon(
                  PhosphorIcons.barbell(),
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'Today at ${timeFormat.format(item.date)}'
                : dateFormat.format(item.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: isActive ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : AppTheme.primaryColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              icon,
              size: 24,
              color: isActive
                  ? (isDark ? AppTheme.primaryColor : Colors.white)
                  : AppTheme.primaryColor,
            ),
            if (!isActive) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

