import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/models/workout.dart';
import '../../../../../../core/providers/repository_providers.dart';
import '../../../../../../core/repositories/client_repository.dart';
import '../../../../../../core/theme/app_theme.dart';

/// Provider for workout progress
final workoutProgressProvider =
    FutureProvider.family<List<WorkoutAssignment>, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  return clientRepo.getClientWorkoutProgress(clientId);
});

class WorkoutProgressTab extends ConsumerWidget {
  final String clientId;

  const WorkoutProgressTab({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(workoutProgressProvider(clientId));

    return progressAsync.when(
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
                  'No workout progress yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Assign workouts to see progress here',
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
            ref.invalidate(workoutProgressProvider(clientId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return FutureBuilder<Workout>(
                future: ref
                    .read(workoutRepositoryProvider)
                    .getWorkoutById(assignment.workoutId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final workout = snapshot.data!;
                  return _WorkoutProgressCard(
                    workout: workout,
                    assignment: assignment,
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
              'Error loading workout progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutProgressCard extends StatelessWidget {
  final Workout workout;
  final WorkoutAssignment assignment;

  const _WorkoutProgressCard({
    required this.workout,
    required this.assignment,
  });

  Color _getStatusColor() {
    switch (assignment.status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  assignment.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Due: ${_formatDate(assignment.dueDate)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${workout.duration} min',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          if (assignment.completedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Completed: ${_formatDate(assignment.completedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

