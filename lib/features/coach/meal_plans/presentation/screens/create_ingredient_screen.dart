import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/models/meal_plan.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'ingredient_list_screen.dart';

class CreateIngredientScreen extends ConsumerStatefulWidget {
  final Ingredient? ingredient; // If provided, we're editing

  const CreateIngredientScreen({
    super.key,
    this.ingredient,
  });

  @override
  ConsumerState<CreateIngredientScreen> createState() =>
      _CreateIngredientScreenState();
}

class _CreateIngredientScreenState
    extends ConsumerState<CreateIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      _nameController.text = widget.ingredient!.name;
      _descriptionController.text = widget.ingredient!.description ?? '';
      _quantityController.text = widget.ingredient!.quantity.toString();
      _unitController.text = widget.ingredient!.unit;
      _caloriesController.text = widget.ingredient!.calories.toString();
      _proteinController.text = widget.ingredient!.protein.toString();
      _carbsController.text = widget.ingredient!.carbs.toString();
      _fatsController.text = widget.ingredient!.fats.toString();
    } else {
      _quantityController.text = '100';
      _unitController.text = 'g';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final mealPlanRepo = ref.read(mealPlanRepositoryProvider);

      final ingredient = Ingredient(
        id: widget.ingredient?.id ?? const Uuid().v4(),
        coachId: user.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        quantity: double.tryParse(_quantityController.text) ?? 100,
        unit: _unitController.text.trim(),
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fats: double.tryParse(_fatsController.text) ?? 0,
        createdAt: widget.ingredient?.createdAt ?? DateTime.now(),
      );

      if (widget.ingredient != null) {
        await mealPlanRepo.updateIngredient(ingredient);
      } else {
        await mealPlanRepo.createIngredient(ingredient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ingredient != null
                  ? 'Ingredient updated successfully'
                  : 'Ingredient created successfully',
            ),
          ),
        );
        ref.invalidate(ingredientListProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving ingredient: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ingredient != null ? 'Edit Ingredient' : 'Add Ingredient',
        ),
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
              onPressed: _saveIngredient,
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
                labelText: 'Ingredient Name *',
                hintText: 'e.g., Chicken Breast',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an ingredient name';
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
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: '100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      hintText: 'g, ml, etc.',
                      border: OutlineInputBorder(),
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
            Text(
              'Nutritional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories *',
                hintText: 'e.g., 165',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein (g) *',
                hintText: 'e.g., 31',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbs (g) *',
                hintText: 'e.g., 0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grain),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fatsController,
              decoration: const InputDecoration(
                labelText: 'Fats (g) *',
                hintText: 'e.g., 3.6',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water_drop),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveIngredient,
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
        label: Text(_isSaving ? 'Saving...' : 'Save Ingredient'),
      ),
    );
  }
}

