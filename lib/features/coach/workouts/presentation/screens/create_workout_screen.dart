import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/exercise_form_tile.dart';

class CreateWorkoutScreen extends ConsumerStatefulWidget {
  final Workout? workout; // If provided, we're editing

  const CreateWorkoutScreen({
    super.key,
    this.workout,
  });

  @override
  ConsumerState<CreateWorkoutScreen> createState() =>
      _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _stepsController = TextEditingController();
  String _difficulty = 'beginner';
  String _category = 'strength_training';
  List<Exercise> _exercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _descriptionController.text = widget.workout!.description ?? '';
      _durationController.text = widget.workout!.duration.toString();
      _difficulty = widget.workout!.difficulty;
      _category = widget.workout!.category;
      _videoUrlController.text = widget.workout!.videoUrl ?? '';
      _stepsController.text = widget.workout!.steps.join('\n');
      _exercises = List.from(widget.workout!.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _videoUrlController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final duration = int.tryParse(_durationController.text) ?? 30;

      // Parse steps from text (split by newlines, filter empty)
      final steps = _stepsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final workout = Workout(
        id: widget.workout?.id ?? const Uuid().v4(),
        coachId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        exercises: _exercises,
        duration: duration,
        difficulty: _difficulty,
        category: _category,
        steps: steps,
        videoUrl: _videoUrlController.text.trim().isEmpty
            ? null
            : _videoUrlController.text.trim(),
        createdAt: widget.workout?.createdAt ?? DateTime.now(),
      );

      if (widget.workout != null) {
        await workoutRepo.updateWorkout(workout);
      } else {
        await workoutRepo.createWorkout(workout);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.workout != null
                  ? 'Workout updated successfully'
                  : 'Workout created successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addExercise() {
    setState(() {
      _exercises.add(
        Exercise(
          id: const Uuid().v4(),
          name: '',
          sets: 3,
          reps: 10,
          restPeriod: 60,
        ),
      );
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _updateExercise(int index, Exercise exercise) {
    setState(() {
      _exercises[index] = exercise;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout != null ? 'Edit Workout' : 'Create Workout'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveWorkout,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name *',
                hintText: 'e.g., Full Body Strength',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a workout name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Text('Beginner'),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Text('Intermediate'),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Text('Advanced'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _difficulty = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                helperText: 'Type of exercise',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cardio',
                  child: Text('Cardio'),
                ),
                DropdownMenuItem(
                  value: 'strength_training',
                  child: Text('Strength Training'),
                ),
                DropdownMenuItem(
                  value: 'flexibility',
                  child: Text('Flexibility'),
                ),
                DropdownMenuItem(
                  value: 'hiit',
                  child: Text('HIIT'),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                hintText: 'YouTube link or video URL',
                border: OutlineInputBorder(),
                helperText: 'Paste a YouTube link or video URL',
                prefixIcon: Icon(Icons.video_library),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stepsController,
              decoration: const InputDecoration(
                labelText: 'Workout Steps/Instructions',
                hintText: 'Enter each step on a new line',
                border: OutlineInputBorder(),
                helperText: 'Add step-by-step instructions (one per line)',
                prefixIcon: Icon(Icons.list),
              ),
              maxLines: 6,
              minLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises (${_exercises.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
            if (_exercises.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No exercises yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add exercises to create your workout',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(
                _exercises.length,
                (index) => ExerciseFormTile(
                  exercise: _exercises[index],
                  onChanged: (exercise) => _updateExercise(index, exercise),
                  onDelete: () => _removeExercise(index),
                ),
              ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveWorkout,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Workout'),
      ),
    );
  }
}

