import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import 'create_workout_screen.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(
      workoutDetailProvider(workoutId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          workoutAsync.when(
            data: (workout) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Assign Workout',
                  onPressed: () {
                    context.push(
                      '/coach/workouts/assign?workoutId=${workout.id}',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Workout',
                  onPressed: () {
                    context.push(
                      '/coach/workouts/create',
                      extra: workout,
                    ).then((_) {
                      // Refresh workout detail when returning from edit
                      ref.invalidate(workoutDetailProvider(workoutId));
                    });
                  },
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: workoutAsync.when(
        data: (workout) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Section
              if (workout.videoUrl != null && workout.videoUrl!.isNotEmpty) ...[
                _VideoSection(videoUrl: workout.videoUrl!),
                const SizedBox(height: 24),
              ],
              // Workout Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (workout.description != null &&
                          workout.description!.isNotEmpty) ...[
                        Text(
                          workout.description!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InfoChip(
                            icon: Icons.category,
                            label: _getCategoryLabel(workout.category),
                            color: _getCategoryColor(workout.category),
                          ),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: '${workout.duration} min',
                            color: AppTheme.accentColor,
                          ),
                          _InfoChip(
                            icon: Icons.trending_up,
                            label: workout.difficulty.substring(0, 1).toUpperCase() +
                                workout.difficulty.substring(1),
                            color: AppTheme.secondaryColor,
                          ),
                          _InfoChip(
                            icon: Icons.fitness_center,
                            label: '${workout.exercises.length} exercises',
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Steps Section
              if (workout.steps.isNotEmpty) ...[
                Text(
                  'How to Perform',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...workout.steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < workout.steps.length - 1 ? 16 : 0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Exercises Section
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...workout.exercises.map((exercise) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (exercise.description != null &&
                              exercise.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              exercise.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (exercise.sets > 0)
                                _InfoChip(
                                  icon: Icons.repeat,
                                  label: '${exercise.sets} sets',
                                  color: AppTheme.primaryColor,
                                ),
                              if (exercise.reps != null)
                                _InfoChip(
                                  icon: Icons.numbers,
                                  label: '${exercise.reps} reps',
                                  color: AppTheme.accentColor,
                                ),
                              if (exercise.duration != null)
                                _InfoChip(
                                  icon: Icons.timer,
                                  label: '${exercise.duration}s',
                                  color: AppTheme.secondaryColor,
                                ),
                              if (exercise.restPeriod > 0)
                                _InfoChip(
                                  icon: Icons.pause_circle,
                                  label: '${exercise.restPeriod}s rest',
                                  color: Colors.grey,
                                ),
                              if (exercise.weight != null)
                                _InfoChip(
                                  icon: Icons.fitness_center,
                                  label: '${exercise.weight}kg',
                                  color: Colors.orange,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
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
                'Error loading workout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'cardio':
        return 'Cardio';
      case 'strength_training':
        return 'Strength Training';
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

class _VideoSection extends StatelessWidget {
  final String videoUrl;

  const _VideoSection({required this.videoUrl});

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  @override
  Widget build(BuildContext context) {
    final isYouTube = _isYouTubeUrl(videoUrl);
    final youtubeId = isYouTube ? _extractYouTubeVideoId(videoUrl) : null;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.video_library, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Workout Video',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          if (isYouTube && youtubeId != null)
            // YouTube embed
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(videoUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Video'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Generic video URL
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Video URL',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    videoUrl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(videoUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Video'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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

/// Provider for workout detail
final workoutDetailProvider = FutureProvider.family<Workout, String>((ref, workoutId) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  return workoutRepo.getWorkoutById(workoutId);
});

