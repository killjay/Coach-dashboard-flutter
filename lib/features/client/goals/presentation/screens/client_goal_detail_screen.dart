import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/models/goal.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

/// Provider for goal detail
final clientGoalDetailProvider = FutureProvider.family<Goal?, String>((ref, goalId) async {
  final goalRepo = ref.watch(goalRepositoryProvider);
  try {
    return await goalRepo.getGoalById(goalId);
  } catch (e) {
    return null;
  }
});

/// Provider for goal progress history
final clientGoalProgressHistoryProvider =
    FutureProvider.family<List<GoalProgressLog>, String>((ref, goalId) async {
  final goalRepo = ref.watch(goalRepositoryProvider);
  try {
    return await goalRepo.getGoalProgressHistory(goalId);
  } catch (e) {
    return [];
  }
});

class ClientGoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const ClientGoalDetailScreen({
    super.key,
    required this.goalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(clientGoalDetailProvider(goalId));
    final progressHistoryAsync = ref.watch(clientGoalProgressHistoryProvider(goalId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
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
                const SizedBox(height: 24),
                // Update Progress Button
                _UpdateProgressButton(goal: goal),
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
            Text(
              goal.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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

class _UpdateProgressButton extends ConsumerStatefulWidget {
  final Goal goal;

  const _UpdateProgressButton({
    required this.goal,
  });

  @override
  ConsumerState<_UpdateProgressButton> createState() =>
      _UpdateProgressButtonState();
}

class _UpdateProgressButtonState extends ConsumerState<_UpdateProgressButton> {
  bool _isUpdating = false;

  Future<void> _updateProgress() async {
    final currentValue = widget.goal.currentValue ?? 0.0;
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current Value (${widget.goal.targetUnit})',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isUpdating = true);

      try {
        final goalRepo = ref.read(goalRepositoryProvider);
        await goalRepo.logGoalProgress(
          GoalProgressLog(
            id: '',
            goalId: widget.goal.id,
            value: result,
            loggedAt: DateTime.now(),
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress updated successfully'),
            ),
          );
          ref.invalidate(clientGoalDetailProvider(widget.goal.id));
          ref.invalidate(clientGoalProgressHistoryProvider(widget.goal.id));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating progress: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _updateProgress,
        icon: _isUpdating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.update_rounded),
        label: Text(_isUpdating ? 'Updating...' : 'Update Progress'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

