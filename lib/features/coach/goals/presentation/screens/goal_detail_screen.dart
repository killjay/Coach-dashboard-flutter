import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/models/goal.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'create_goal_screen.dart';

/// Provider for goal detail
final goalDetailProvider = FutureProvider.family<Goal?, String>((ref, goalId) async {
  final goalRepo = ref.watch(goalRepositoryProvider);
  try {
    return await goalRepo.getGoalById(goalId);
  } catch (e) {
    return null;
  }
});

/// Provider for goal progress history
final goalProgressHistoryProvider =
    FutureProvider.family<List<GoalProgressLog>, String>((ref, goalId) async {
  final goalRepo = ref.watch(goalRepositoryProvider);
  try {
    return await goalRepo.getGoalProgressHistory(goalId);
  } catch (e) {
    return [];
  }
});

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalDetailProvider(goalId));
    final progressHistoryAsync = ref.watch(goalProgressHistoryProvider(goalId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          goalAsync.when(
            data: (goal) => goal != null
                ? IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit Goal',
                    onPressed: () {
                      context.push(
                        '/coach/goals/create',
                        extra: goal,
                      );
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: goalAsync.when(
        data: (goal) {
          if (goal == null) {
            return Center(
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
                    'Goal not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Header Card
                _GoalHeaderCard(goal: goal, isDark: isDark),
                const SizedBox(height: 24),
                // Progress Section
                _ProgressSection(
                  goal: goal,
                  progressHistoryAsync: progressHistoryAsync,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                // Milestones Section
                if (goal.milestones != null && goal.milestones!.isNotEmpty)
                  _MilestonesSection(
                    goal: goal,
                    isDark: isDark,
                  ),
              ],
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
                'Error loading goal',
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
}

class _GoalHeaderCard extends StatelessWidget {
  final Goal goal;
  final bool isDark;

  const _GoalHeaderCard({
    required this.goal,
    required this.isDark,
  });

  Color _getStatusColor() {
    switch (goal.status) {
      case GoalStatus.active:
        return Colors.blue;
      case GoalStatus.completed:
        return Colors.green;
      case GoalStatus.paused:
        return Colors.orange;
      case GoalStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercentage ?? 0.0;
    final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: 12),
              Text(
                goal.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 12,
                    backgroundColor: isDark
                        ? AppTheme.darkSurfaceVariant
                        : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.track_changes_rounded,
                    label: 'Target',
                    value: '${goal.targetValue} ${goal.targetUnit}',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Current',
                    value: goal.currentValue != null
                        ? '${goal.currentValue!.toStringAsFixed(1)} ${goal.targetUnit}'
                        : 'Not set',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Days Left',
                    value: daysRemaining > 0 ? '$daysRemaining' : 'Overdue',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextHint
                    : AppTheme.textHint,
              ),
        ),
      ],
    );
  }
}

class _ProgressSection extends ConsumerWidget {
  final Goal goal;
  final AsyncValue<List<GoalProgressLog>> progressHistoryAsync;
  final bool isDark;

  const _ProgressSection({
    required this.goal,
    required this.progressHistoryAsync,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            progressHistoryAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.show_chart_outlined,
                            size: 48,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No progress logged yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Simple line chart
                return SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: history.asMap().entries.map((entry) {
                            final index = entry.key;
                            final log = entry.value;
                            return FlSpot(index.toDouble(), log.value);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Error loading progress'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  final Goal goal;
  final bool isDark;

  const _MilestonesSection({
    required this.goal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...goal.milestones!.map((milestone) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfaceVariant
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      milestone.isCompleted == true
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: milestone.isCompleted == true
                          ? Colors.green
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: milestone.isCompleted == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${milestone.targetValue} ${goal.targetUnit} by ${DateFormat('MMM d').format(milestone.targetDate)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.darkTextHint
                                      : AppTheme.textHint,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

