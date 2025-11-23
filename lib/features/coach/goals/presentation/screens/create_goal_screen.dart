import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/goal.dart';
import '../../../../../core/models/user.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../clients/presentation/screens/client_list_screen.dart' show clientListProvider;

class CreateGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal; // For editing
  final String? clientId; // Pre-select a client

  const CreateGoalScreen({
    super.key,
    this.goal,
    this.clientId,
  });

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _targetUnitController = TextEditingController();

  String? _selectedClientId;
  GoalType _selectedType = GoalType.weightLoss;
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descriptionController.text = widget.goal!.description ?? '';
      _targetValueController.text = widget.goal!.targetValue.toString();
      _targetUnitController.text = widget.goal!.targetUnit;
      _selectedClientId = widget.goal!.clientId;
      _selectedType = widget.goal!.type;
      _startDate = widget.goal!.startDate;
      _targetDate = widget.goal!.targetDate;
    } else {
      _targetUnitController.text = _getDefaultUnit(_selectedType);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _targetUnitController.dispose();
    super.dispose();
  }

  String _getDefaultUnit(GoalType type) {
    switch (type) {
      case GoalType.weightLoss:
      case GoalType.weightGain:
      case GoalType.muscleGain:
        return 'kg';
      case GoalType.bodyFatReduction:
        return '%';
      case GoalType.waterIntake:
        return 'liters';
      case GoalType.steps:
        return 'steps';
      case GoalType.workoutCompletion:
        return 'workouts';
      default:
        return '';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_targetDate.isBefore(_startDate)) {
            _targetDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _targetDate = picked;
        }
      });
    }
  }

  Future<void> _saveGoal() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Additional validation checks
    if (_selectedClientId == null || _selectedClientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_targetDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target date must be after start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate target value
    final targetValueText = _targetValueController.text.trim();
    if (targetValueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a target value'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final targetValue = double.tryParse(targetValueText);
    if (targetValue == null || targetValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target value (greater than 0)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate target unit
    final targetUnit = _targetUnitController.text.trim();
    if (targetUnit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a target unit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.role != 'coach') {
        throw Exception('User not authenticated as coach');
      }

      final goalRepo = ref.read(goalRepositoryProvider);

      final goal = Goal(
        id: widget.goal?.id ?? '',
        clientId: _selectedClientId!,
        coachId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        targetValue: targetValue,
        targetUnit: targetUnit,
        currentValue: widget.goal?.currentValue,
        startDate: _startDate,
        targetDate: _targetDate,
        status: widget.goal?.status ?? GoalStatus.active,
        progressPercentage: widget.goal?.progressPercentage,
        milestones: widget.goal?.milestones,
        completedAt: widget.goal?.completedAt,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
      );

      if (widget.goal != null) {
        await goalRepo.updateGoal(goal);
      } else {
        await goalRepo.createGoal(goal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.goal != null
                  ? 'Goal updated successfully'
                  : 'Goal created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving goal: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal != null ? 'Edit Goal' : 'Create Goal'),
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
              onPressed: _saveGoal,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Selection
              Text(
                'Client',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              clientsAsync.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: null,
                          decoration: InputDecoration(
                            labelText: 'Select Client *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            errorText: 'No clients available. Please add a client first.',
                          ),
                          items: const [],
                          onChanged: (value) {},
                          validator: (value) {
                            return 'No clients available. Please add a client first.';
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/coach/clients/add');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Client'),
                        ),
                      ],
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedClientId,
                    decoration: InputDecoration(
                      labelText: 'Select Client *',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a client';
                      }
                      return null;
                    },
                  );
                },
                loading: () => DropdownButtonFormField<String>(
                  initialValue: null,
                  decoration: InputDecoration(
                    labelText: 'Select Client *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  items: const [],
                  onChanged: (value) {},
                  validator: (value) {
                    return 'Loading clients...';
                  },
                ),
                error: (error, stack) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: null,
                      decoration: InputDecoration(
                        labelText: 'Select Client *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: const Icon(Icons.person),
                        errorText: 'Error loading clients. Please try again.',
                      ),
                      items: const [],
                      onChanged: (value) {},
                      validator: (value) {
                        return 'Error loading clients';
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${error.toString()}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Goal Type
              Text(
                'Goal Type',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GoalType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getGoalTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      _targetUnitController.text = _getDefaultUnit(value);
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a goal type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Goal Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Target Value
              Text(
                'Target',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetValueController,
                      decoration: InputDecoration(
                        labelText: 'Target Value *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: const Icon(Icons.track_changes),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _targetUnitController,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Dates
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Target Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.event),
                        ),
                        child: Text(DateFormat('MMM d, yyyy').format(_targetDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveGoal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.goal != null ? 'Update Goal' : 'Create Goal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGoalTypeLabel(GoalType type) {
    switch (type) {
      case GoalType.weightLoss:
        return 'Weight Loss';
      case GoalType.weightGain:
        return 'Weight Gain';
      case GoalType.muscleGain:
        return 'Muscle Gain';
      case GoalType.bodyFatReduction:
        return 'Body Fat Reduction';
      case GoalType.endurance:
        return 'Endurance';
      case GoalType.strength:
        return 'Strength';
      case GoalType.flexibility:
        return 'Flexibility';
      case GoalType.waterIntake:
        return 'Water Intake';
      case GoalType.steps:
        return 'Steps';
      case GoalType.workoutCompletion:
        return 'Workout Completion';
      case GoalType.custom:
        return 'Custom';
    }
  }
}

