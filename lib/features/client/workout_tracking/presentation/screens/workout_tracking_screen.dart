import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for assigned workouts
final assignedWorkoutsProvider = FutureProvider<List<WorkoutAssignment>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return [];
  }
  
  return workoutRepo.getAssignedWorkouts(user.id);
});

class WorkoutTrackingScreen extends ConsumerWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignedWorkoutsProvider);
    final workoutRepo = ref.watch(workoutRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workouts'),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
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
                    'No workouts assigned',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your coach will assign workouts to you',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(assignedWorkoutsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return FutureBuilder<Workout>(
                  future: workoutRepo.getWorkoutById(assignment.workoutId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Card(
                        child: ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('Loading...'),
                        ),
                      );
                    }

                    final workout = snapshot.data!;
                    return _WorkoutAssignmentCard(
                      workout: workout,
                      assignment: assignment,
                      onStart: () {
                        context.push(
                          '/client/workouts/execute',
                          extra: {
                            'workoutId': workout.id,
                            'assignmentId': assignment.id,
                          },
                        );
                      },
                      onComplete: () async {
                        try {
                          await workoutRepo.updateWorkoutAssignmentStatus(
                            assignmentId: assignment.id,
                            status: 'completed',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Workout marked as completed!'),
                              ),
                            );
                            ref.invalidate(assignedWorkoutsProvider);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(assignedWorkoutsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutAssignmentCard extends StatelessWidget {
  final Workout workout;
  final WorkoutAssignment assignment;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _WorkoutAssignmentCard({
    required this.workout,
    required this.assignment,
    required this.onStart,
    required this.onComplete,
  });

  Color _getStatusColor() {
    switch (assignment.status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = assignment.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workout.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    assignment.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor().withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: _getStatusColor()),
                ),
              ],
            ),
            if (workout.description != null) ...[
              const SizedBox(height: 8),
              Text(
                workout.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: '${workout.exercises.length} exercises',
                ),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '${workout.duration} min',
                ),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: 'Due: ${_formatDate(assignment.dueDate)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Workout'),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isCompleted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Complete'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0 && difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

