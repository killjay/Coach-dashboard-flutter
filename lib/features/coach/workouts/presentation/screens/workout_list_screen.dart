import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../core/utils/router.dart';
import '../../../../../core/theme/app_theme.dart';

/// Provider for workout list
final workoutListProvider = FutureProvider<List<Workout>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return [];
  }
  
  return workoutRepo.getWorkouts(user.id);
});

/// Provider for workout assignment counts
final workoutAssignmentCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final workoutsAsync = ref.watch(workoutListProvider);
  
  final workouts = workoutsAsync.value ?? [];
  final counts = <String, int>{};
  
  for (final workout in workouts) {
    try {
      final count = await workoutRepo.getWorkoutAssignmentCount(workout.id);
      counts[workout.id] = count;
    } catch (e) {
      counts[workout.id] = 0;
    }
  }
  
  return counts;
});

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutListProvider);
    final workoutRepo = ref.watch(workoutRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Calendar View',
            onPressed: () {
              context.push(AppRoutes.workoutCalendar);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Workout',
            onPressed: () {
              context.push(AppRoutes.createWorkout);
            },
          ),
        ],
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workouts yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first workout to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                  onPressed: () {
                    context.push(AppRoutes.createWorkout);
                  },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Workout'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(workoutListProvider);
              ref.invalidate(workoutAssignmentCountsProvider);
            },
            child: Consumer(
              builder: (context, ref, child) {
                final countsAsync = ref.watch(workoutAssignmentCountsProvider);
                return countsAsync.when(
                  data: (counts) => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return _WorkoutCard(
                        workout: workout,
                        assignmentCount: counts[workout.id] ?? 0,
                        onTap: () {
                          context.push('/coach/workouts/${workout.id}');
                        },
                        onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Workout'),
                        content: Text(
                          'Are you sure you want to delete "${workout.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        await workoutRepo.deleteWorkout(workout.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Workout deleted successfully'),
                            ),
                          );
                          ref.invalidate(workoutListProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting workout: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return _WorkoutCard(
                        workout: workout,
                        assignmentCount: 0,
                        onTap: () {},
                        onDelete: () async {},
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading workouts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(workoutListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
                  onPressed: () {
                    context.push(AppRoutes.createWorkout);
                  },
        icon: const Icon(Icons.add),
        label: const Text('Create Workout'),
      ),
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  final Workout workout;
  final int assignmentCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.assignmentCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.05),
            blurRadius: _isHovered ? 20 : 10,
            offset: Offset(0, _isHovered ? 8 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isHovered = true),
          onTapUp: (_) => setState(() => _isHovered = false),
          onTapCancel: () => setState(() => _isHovered = false),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workout.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (widget.workout.description != null &&
                              widget.workout.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.workout.description!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoChip(
                      icon: Icons.category,
                      label: _getCategoryLabel(widget.workout.category),
                      color: _getCategoryColor(widget.workout.category),
                    ),
                    _InfoChip(
                      icon: Icons.fitness_center,
                      label: '${widget.workout.exercises.length} exercises',
                      color: AppTheme.primaryColor,
                    ),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '${widget.workout.duration} min',
                      color: AppTheme.accentColor,
                    ),
                    _InfoChip(
                      icon: Icons.trending_up,
                      label: difficulty,
                      color: AppTheme.secondaryColor,
                    ),
                    _InfoChip(
                      icon: Icons.people,
                      label: '${widget.assignmentCount} clients',
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get difficulty {
    return widget.workout.difficulty.substring(0, 1).toUpperCase() +
        widget.workout.difficulty.substring(1);
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'cardio':
        return 'Cardio';
      case 'strength_training':
        return 'Strength';
      case 'flexibility':
        return 'Flexibility';
      case 'hiit':
        return 'HIIT';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'cardio':
        return Colors.red;
      case 'strength_training':
        return Colors.blue;
      case 'flexibility':
        return Colors.purple;
      case 'hiit':
        return Colors.orange;
      case 'other':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

