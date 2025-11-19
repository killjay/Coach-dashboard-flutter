import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/models/meal_plan.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'create_ingredient_screen.dart';

/// Provider for ingredient list
final ingredientListProvider = FutureProvider<List<Ingredient>>((ref) async {
  final mealPlanRepo = ref.watch(mealPlanRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  return mealPlanRepo.getIngredients(user.id);
});

class IngredientListScreen extends ConsumerWidget {
  const IngredientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Ingredient',
            onPressed: () {
              context.push('/coach/meal-plans/ingredients/create');
            },
          ),
        ],
      ),
      body: ingredientsAsync.when(
        data: (ingredients) {
          if (ingredients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ingredients yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add ingredients to build your meal plans',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/coach/meal-plans/ingredients/create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ingredientListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                return _IngredientCard(
                  ingredient: ingredient,
                  onTap: () {
                    context.push(
                      '/coach/meal-plans/ingredients/create',
                      extra: ingredient,
                    );
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Ingredient'),
                        content: Text(
                          'Are you sure you want to delete "${ingredient.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        await ref
                            .read(mealPlanRepositoryProvider)
                            .deleteIngredient(ingredient.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ingredient deleted successfully'),
                            ),
                          );
                          ref.invalidate(ingredientListProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting ingredient: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
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
                'Error loading ingredients',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(ingredientListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/coach/meal-plans/ingredients/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Ingredient'),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _IngredientCard({
    required this.ingredient,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ingredient.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (ingredient.description != null &&
                              ingredient.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ingredient.description!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nutritional Info (per ${ingredient.quantity}${ingredient.unit})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _NutritionChip(
                      icon: Icons.local_fire_department,
                      label: '${ingredient.calories} cal',
                      color: Colors.orange,
                    ),
                    _NutritionChip(
                      icon: Icons.fitness_center,
                      label: '${ingredient.protein}g protein',
                      color: Colors.blue,
                    ),
                    _NutritionChip(
                      icon: Icons.grain,
                      label: '${ingredient.carbs}g carbs',
                      color: Colors.green,
                    ),
                    _NutritionChip(
                      icon: Icons.water_drop,
                      label: '${ingredient.fats}g fats',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NutritionChip({
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

