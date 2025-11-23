import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/workout.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../clients/presentation/screens/client_list_screen.dart' show clientListProvider;

/// Provider for workouts list
final workoutsListProvider = FutureProvider<List<Workout>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return [];
  }

  return workoutRepo.getWorkouts(user.id);
});

class AssignWorkoutScreen extends ConsumerStatefulWidget {
  final String? clientId; // Pre-select a client
  final String? workoutId; // Pre-select a workout

  const AssignWorkoutScreen({
    super.key,
    this.clientId,
    this.workoutId,
  });

  @override
  ConsumerState<AssignWorkoutScreen> createState() =>
      _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends ConsumerState<AssignWorkoutScreen> {
  String? _selectedClientId;
  String? _selectedWorkoutId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
    _selectedWorkoutId = widget.workoutId;
    
    // Debug: Log the workout ID if provided
    if (widget.workoutId != null) {
      debugPrint('AssignWorkoutScreen: Pre-selected workout ID: ${widget.workoutId}');
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _assignWorkout() async {
    if (_selectedClientId == null || _selectedWorkoutId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a client and a workout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedWorkoutId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid workout selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_dueDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due date must be in the future'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);

      // First verify the workout exists
      try {
        await workoutRepo.getWorkoutById(_selectedWorkoutId!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workout not found. Please select a valid workout.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          setState(() => _isAssigning = false);
          return;
        }
      }

      await workoutRepo.assignWorkout(
        workoutId: _selectedWorkoutId!,
        clientId: _selectedClientId!,
        dueDate: _dueDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout assigned successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning workout: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final workoutsAsync = ref.watch(workoutsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Workout'),
        actions: [
          if (_isAssigning)
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
              onPressed: _assignWorkout,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Selection
            Text(
              'Select Client',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            clientsAsync.when(
              data: (clients) {
                if (clients.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No clients available. Add clients first.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: InputDecoration(
                    labelText: 'Client *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: clients.map((client) {
                    return DropdownMenuItem(
                      value: client.id,
                      child: Text('${client.name} (${client.email})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedClientId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Card(
                color: AppTheme.errorColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error loading clients',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Workout Selection
            Text(
              'Select Workout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            workoutsAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No workouts available. Create workouts first.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedWorkoutId,
                  decoration: InputDecoration(
                    labelText: 'Workout *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.fitness_center),
                  ),
                  items: workouts.map((workout) {
                    return DropdownMenuItem(
                      value: workout.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            workout.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${workout.exercises.length} exercises • ${workout.duration} min',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedWorkoutId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Card(
                color: AppTheme.errorColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error loading workouts',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Due Date Selection
            Text(
              'Due Date',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDueDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_dueDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Assign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAssigning ? null : _assignWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isAssigning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Assign Workout',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

