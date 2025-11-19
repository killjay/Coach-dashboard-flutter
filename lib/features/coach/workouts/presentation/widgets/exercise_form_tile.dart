import 'package:flutter/material.dart';
import '../../../../../core/models/workout.dart';

class ExerciseFormTile extends StatefulWidget {
  final Exercise exercise;
  final ValueChanged<Exercise> onChanged;
  final VoidCallback onDelete;

  const ExerciseFormTile({
    super.key,
    required this.exercise,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ExerciseFormTile> createState() => _ExerciseFormTileState();
}

class _ExerciseFormTileState extends State<ExerciseFormTile> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _durationController;
  late TextEditingController _restController;
  late TextEditingController _weightController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _descriptionController =
        TextEditingController(text: widget.exercise.description ?? '');
    _setsController = TextEditingController(text: widget.exercise.sets.toString());
    _repsController =
        TextEditingController(text: widget.exercise.reps?.toString() ?? '');
    _durationController =
        TextEditingController(text: widget.exercise.duration?.toString() ?? '');
    _restController =
        TextEditingController(text: widget.exercise.restPeriod.toString());
    _weightController =
        TextEditingController(text: widget.exercise.weight?.toString() ?? '');

    // Add listeners to update exercise on change
    _nameController.addListener(_updateExercise);
    _descriptionController.addListener(_updateExercise);
    _setsController.addListener(_updateExercise);
    _repsController.addListener(_updateExercise);
    _durationController.addListener(_updateExercise);
    _restController.addListener(_updateExercise);
    _weightController.addListener(_updateExercise);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _restController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateExercise() {
    widget.onChanged(
      widget.exercise.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sets: int.tryParse(_setsController.text) ?? 3,
        reps: _repsController.text.isEmpty
            ? null
            : int.tryParse(_repsController.text),
        duration: _durationController.text.isEmpty
            ? null
            : int.tryParse(_durationController.text),
        restPeriod: int.tryParse(_restController.text) ?? 60,
        weight: _weightController.text.isEmpty
            ? null
            : double.tryParse(_weightController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: widget.exercise.name.isEmpty,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        leading: Icon(
          Icons.fitness_center,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          widget.exercise.name.isEmpty ? 'New Exercise' : widget.exercise.name,
          style: TextStyle(
            fontWeight: _isExpanded ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: _isExpanded
            ? null
            : Text(
                '${widget.exercise.sets} sets × ${widget.exercise.reps ?? widget.exercise.duration}${widget.exercise.reps != null ? ' reps' : ' sec'}',
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: widget.onDelete,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: 'e.g., Push-ups',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        decoration: const InputDecoration(
                          labelText: 'Sets *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        decoration: const InputDecoration(
                          labelText: 'Reps',
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (sec)',
                          hintText: 'If time-based',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _restController,
                        decoration: const InputDecoration(
                          labelText: 'Rest (sec) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

