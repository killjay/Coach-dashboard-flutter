import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/models/meal_plan.dart';
import '../../../../../../core/providers/repository_providers.dart';
import '../../../../../../core/repositories/meal_plan_repository.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/responsive.dart';

/// Provider for meal completions for a client
final mealCompletionsProvider =
    FutureProvider.family<List<MealCompletion>, String>((ref, clientId) async {
  final mealPlanRepo = ref.watch(mealPlanRepositoryProvider);
  
  // Get last 30 days of meal completions
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 30));
  
  return mealPlanRepo.getMealCompletions(
    clientId: clientId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// Meals Consumed Tab following Apple HIG principles:
/// - Clarity: Clear chronological organization
/// - Deference: Content-first design
/// - Depth: Subtle visual hierarchy
class MealsConsumedTab extends ConsumerWidget {
  final String clientId;

  const MealsConsumedTab({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionsAsync = ref.watch(mealCompletionsProvider(clientId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return completionsAsync.when(
      data: (completions) {
        if (completions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 64,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No meals tracked yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Meal completions will appear here once the client starts tracking',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Group completions by date
        final groupedCompletions = <DateTime, List<MealCompletion>>{};
        for (final completion in completions) {
          final date = DateTime(
            completion.date.year,
            completion.date.month,
            completion.date.day,
          );
          groupedCompletions.putIfAbsent(date, () => []).add(completion);
        }

        final sortedDates = groupedCompletions.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(mealCompletionsProvider(clientId));
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.padding.left,
              vertical: responsive.padding.top,
            ),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayCompletions = groupedCompletions[date]!;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return _MealDayCard(
                date: date,
                completions: dayCompletions,
                isToday: isToday,
                isDark: isDark,
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
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading meal data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(mealCompletionsProvider(clientId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Meal Day Card - Apple HIG: Clear grouping with depth
class _MealDayCard extends StatelessWidget {
  final DateTime date;
  final List<MealCompletion> completions;
  final bool isToday;
  final bool isDark;

  const _MealDayCard({
    required this.date,
    required this.completions,
    required this.isToday,
    required this.isDark,
  });

  String _getMealTypeIcon(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '🍽️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'Today' : dateFormat.format(date),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${completions.length} ${completions.length == 1 ? 'meal' : 'meals'} completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${completions.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Completions list
          ...completions.map((completion) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getMealTypeIcon(null), // Would need meal type from meal data
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal Completed',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (completion.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            completion.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (completion.rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < completion.rating!.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormat.format(completion.completedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
