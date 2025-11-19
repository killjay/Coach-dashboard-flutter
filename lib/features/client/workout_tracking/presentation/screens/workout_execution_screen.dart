import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/models/workout_log.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/repositories/workout_repository.dart';
import '../../../../../core/repositories/workout_log_repository.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for workout execution state
final workoutExecutionProvider =
    StateNotifierProvider.autoDispose<WorkoutExecutionNotifier, WorkoutExecutionState>(
  (ref) {
    final workoutLogRepo = ref.watch(workoutLogRepositoryProvider);
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    return WorkoutExecutionNotifier(
      workoutLogRepo: workoutLogRepo,
      workoutRepo: workoutRepo,
      userId: user?.id ?? '',
    );
  },
);

class WorkoutExecutionState {
  final WorkoutLog? workoutLog;
  final Map<String, ExerciseLog> exerciseLogs;
  final int? currentExerciseIndex;
  final int? currentSetIndex;
  final bool isResting;
  final int restTimeRemaining;
  final bool isCompleted;

  WorkoutExecutionState({
    this.workoutLog,
    required this.exerciseLogs,
    this.currentExerciseIndex,
    this.currentSetIndex,
    this.isResting = false,
    this.restTimeRemaining = 0,
    this.isCompleted = false,
  });

  WorkoutExecutionState copyWith({
    WorkoutLog? workoutLog,
    Map<String, ExerciseLog>? exerciseLogs,
    int? currentExerciseIndex,
    int? currentSetIndex,
    bool? isResting,
    int? restTimeRemaining,
    bool? isCompleted,
  }) {
    return WorkoutExecutionState(
      workoutLog: workoutLog ?? this.workoutLog,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      isResting: isResting ?? this.isResting,
      restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class WorkoutExecutionNotifier extends StateNotifier<WorkoutExecutionState> {
  final WorkoutLogRepository workoutLogRepo;
  final WorkoutRepository workoutRepo;
  final String userId;

  WorkoutExecutionNotifier({
    required this.workoutLogRepo,
    required this.workoutRepo,
    required this.userId,
  }) : super(WorkoutExecutionState(exerciseLogs: {}));

  Future<void> startWorkout({
    required String workoutId,
    required String assignmentId,
  }) async {
    try {
      final workoutLog = await workoutLogRepo.startWorkout(
        workoutId: workoutId,
        assignmentId: assignmentId,
        clientId: userId,
      );
      state = state.copyWith(workoutLog: workoutLog);
    } catch (e) {
      throw Exception('Failed to start workout: $e');
    }
  }

  void logSet({
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    int? reps,
    double? weight,
    int? duration,
    bool isCompleted = true,
  }) {
    final currentLog = state.exerciseLogs[exerciseId];
    final sets = currentLog?.sets ?? [];
    
    // Update or add set
    final setIndex = sets.indexWhere((s) => s.setNumber == setNumber);
    final newSet = SetLog(
      setNumber: setNumber,
      reps: reps,
      weight: weight,
      duration: duration,
      isCompleted: isCompleted,
    );

    final updatedSets = setIndex >= 0
        ? sets.map((s) => s.setNumber == setNumber ? newSet : s).toList()
        : [...sets, newSet]..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    final updatedLog = ExerciseLog(
      id: currentLog?.id ?? '',
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: updatedSets,
      notes: currentLog?.notes,
    );

    final updatedLogs = Map<String, ExerciseLog>.from(state.exerciseLogs);
    updatedLogs[exerciseId] = updatedLog;

    state = state.copyWith(exerciseLogs: updatedLogs);

    // Save to Firebase
    if (state.workoutLog != null) {
      workoutLogRepo.saveExerciseLog(
        workoutLogId: state.workoutLog!.id,
        exerciseLog: updatedLog,
      );
    }
  }

  void startRest(int restPeriod) {
    state = state.copyWith(isResting: true, restTimeRemaining: restPeriod);
  }

  void updateRestTime(int remaining) {
    state = state.copyWith(restTimeRemaining: remaining);
    if (remaining <= 0) {
      state = state.copyWith(isResting: false, restTimeRemaining: 0);
    }
  }

  void stopRest() {
    state = state.copyWith(isResting: false, restTimeRemaining: 0);
  }

  Future<void> completeWorkout({String? notes}) async {
    if (state.workoutLog == null) return;

    try {
      await workoutLogRepo.completeWorkout(
        workoutLogId: state.workoutLog!.id,
        notes: notes,
      );
      state = state.copyWith(isCompleted: true);
    } catch (e) {
      throw Exception('Failed to complete workout: $e');
    }
  }
}

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final String assignmentId;

  const WorkoutExecutionScreen({
    super.key,
    required this.workoutId,
    required this.assignmentId,
  });

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  Workout? _workout;
  bool _isLoading = true;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = await workoutRepo.getWorkoutById(widget.workoutId);
      
      if (mounted) {
        setState(() {
          _workout = workout;
          _isLoading = false;
        });
        
        // Start workout session
        await ref.read(workoutExecutionProvider.notifier).startWorkout(
              workoutId: widget.workoutId,
              assignmentId: widget.assignmentId,
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Workout...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final executionState = ref.watch(workoutExecutionProvider);
    final notifier = ref.read(workoutExecutionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_workout!.name),
        actions: [
          if (executionState.workoutLog != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _showCompleteDialog(notifier),
            ),
        ],
      ),
      body: Column(
        children: [
          // Rest timer banner
          if (executionState.isResting)
            _RestTimerBanner(
              timeRemaining: executionState.restTimeRemaining,
              onStop: () => notifier.stopRest(),
            ),
          
          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workout!.exercises.length,
              itemBuilder: (context, index) {
                final exercise = _workout!.exercises[index];
                final exerciseLog = executionState.exerciseLogs[exercise.id];
                return _ExerciseCard(
                  exercise: exercise,
                  exerciseLog: exerciseLog,
                  onLogSet: (setNumber, reps, weight, duration) {
                    notifier.logSet(
                      exerciseId: exercise.id,
                      exerciseName: exercise.name,
                      setNumber: setNumber,
                      reps: reps,
                      weight: weight,
                      duration: duration,
                    );
                  },
                  onStartRest: () {
                    notifier.startRest(exercise.restPeriod);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompleteDialog(WorkoutExecutionNotifier notifier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add any notes about your workout:'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Optional notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await notifier.completeWorkout(
                  notes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context, true);
                  context.pop(true); // Return to workout list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class _RestTimerBanner extends StatefulWidget {
  final int timeRemaining;
  final VoidCallback onStop;

  const _RestTimerBanner({
    required this.timeRemaining,
    required this.onStop,
  });

  @override
  State<_RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends State<_RestTimerBanner> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && widget.timeRemaining > 0) {
        setState(() {});
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.timeRemaining ~/ 60;
    final seconds = widget.timeRemaining % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade700,
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            'Rest: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white),
            onPressed: widget.onStop,
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final ExerciseLog? exerciseLog;
  final Function(int setNumber, int? reps, double? weight, int? duration) onLogSet;
  final VoidCallback onStartRest;

  const _ExerciseCard({
    required this.exercise,
    this.exerciseLog,
    required this.onLogSet,
    required this.onStartRest,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _durationControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each set
    for (int i = 1; i <= widget.exercise.sets; i++) {
      _repsControllers[i] = TextEditingController();
      _weightControllers[i] = TextEditingController();
      _durationControllers[i] = TextEditingController();
      
      // Pre-fill with previous values if available
      if (widget.exerciseLog != null) {
        final existingSet = widget.exerciseLog!.sets
            .firstWhere((s) => s.setNumber == i, orElse: () => const SetLog(setNumber: 0));
        if (existingSet.setNumber == i) {
          if (existingSet.reps != null) {
            _repsControllers[i]!.text = existingSet.reps.toString();
          }
          if (existingSet.weight != null) {
            _weightControllers[i]!.text = existingSet.weight.toString();
          }
          if (existingSet.duration != null) {
            _durationControllers[i]!.text = existingSet.duration.toString();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _repsControllers.values) {
      controller.dispose();
    }
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _durationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.exercise.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.exercise.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 16),
            // Sets
            ...List.generate(widget.exercise.sets, (index) {
              final setNumber = index + 1;
              final setLog = widget.exerciseLog?.sets
                  .firstWhere(
                    (s) => s.setNumber == setNumber,
                    orElse: () => const SetLog(setNumber: 0),
                  );
              final isCompleted = setLog?.isCompleted ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Set number
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$setNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reps input
                    if (widget.exercise.reps != null)
                      Expanded(
                        child: TextField(
                          controller: _repsControllers[setNumber],
                          decoration: InputDecoration(
                            labelText: 'Reps',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    if (widget.exercise.reps != null) const SizedBox(width: 8),
                    // Weight input
                    if (widget.exercise.weight != null)
                      Expanded(
                        child: TextField(
                          controller: _weightControllers[setNumber],
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    if (widget.exercise.weight != null) const SizedBox(width: 8),
                    // Duration input
                    if (widget.exercise.duration != null)
                      Expanded(
                        child: TextField(
                          controller: _durationControllers[setNumber],
                          decoration: InputDecoration(
                            labelText: 'Duration (s)',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Complete button
                    IconButton(
                      icon: Icon(
                        isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        final reps = _repsControllers[setNumber]?.text.isNotEmpty == true
                            ? int.tryParse(_repsControllers[setNumber]!.text)
                            : null;
                        final weight = _weightControllers[setNumber]?.text.isNotEmpty == true
                            ? double.tryParse(_weightControllers[setNumber]!.text)
                            : null;
                        final duration = _durationControllers[setNumber]?.text.isNotEmpty == true
                            ? int.tryParse(_durationControllers[setNumber]!.text)
                            : null;

                        widget.onLogSet(setNumber, reps, weight, duration);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            // Start rest button
            OutlinedButton.icon(
              onPressed: widget.onStartRest,
              icon: const Icon(Icons.timer),
              label: Text('Rest ${widget.exercise.restPeriod}s'),
            ),
          ],
        ),
      ),
    );
  }
}

