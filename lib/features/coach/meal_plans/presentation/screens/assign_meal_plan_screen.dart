import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/meal_plan.dart';
import '../../../../../core/models/user.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../clients/presentation/screens/client_list_screen.dart' show clientListProvider;

/// Provider for meal plans list
final mealPlansListProvider = FutureProvider<List<MealPlan>>((ref) async {
  final mealPlanRepo = ref.watch(mealPlanRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return [];
  }

  return mealPlanRepo.getMealPlans(user.id);
});

class AssignMealPlanScreen extends ConsumerStatefulWidget {
  final String? clientId; // Pre-select a client
  final String? mealPlanId; // Pre-select a meal plan

  const AssignMealPlanScreen({
    super.key,
    this.clientId,
    this.mealPlanId,
  });

  @override
  ConsumerState<AssignMealPlanScreen> createState() =>
      _AssignMealPlanScreenState();
}

class _AssignMealPlanScreenState extends ConsumerState<AssignMealPlanScreen> {
  String? _selectedClientId;
  String? _selectedMealPlanId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
    _selectedMealPlanId = widget.mealPlanId;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _assignMealPlan() async {
    if (_selectedClientId == null || _selectedMealPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a client and a meal plan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final mealPlanRepo = ref.read(mealPlanRepositoryProvider);

      await mealPlanRepo.assignMealPlan(
        mealPlanId: _selectedMealPlanId!,
        clientId: _selectedClientId!,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal plan assigned successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning meal plan: $e'),
            backgroundColor: Colors.red,
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
    final mealPlansAsync = ref.watch(mealPlansListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Meal Plan'),
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
              onPressed: _assignMealPlan,
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
              data: (clients) => DropdownButtonFormField<String>(
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
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading clients'),
            ),
            const SizedBox(height: 24),
            // Meal Plan Selection
            Text(
              'Select Meal Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            mealPlansAsync.when(
              data: (mealPlans) {
                final actualMealPlans = mealPlans
                    .where((mp) => mp.category == 'meal_plan')
                    .toList();

                if (actualMealPlans.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 48,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meal plans available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a meal plan first',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextHint
                                      : AppTheme.textHint,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedMealPlanId,
                  decoration: InputDecoration(
                    labelText: 'Meal Plan *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.restaurant_menu),
                  ),
                  items: actualMealPlans.map((mealPlan) {
                    return DropdownMenuItem(
                      value: mealPlan.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mealPlan.name),
                          Text(
                            '${mealPlan.duration} days • ${mealPlan.totalCalories} cal/day',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextHint
                                      : AppTheme.textHint,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedMealPlanId = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading meal plans'),
            ),
            const SizedBox(height: 24),
            // Date Selection
            Text(
              'Schedule',
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
                        labelText: 'End Date *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: const Icon(Icons.event),
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Assign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAssigning ? null : _assignMealPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isAssigning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Assign Meal Plan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

