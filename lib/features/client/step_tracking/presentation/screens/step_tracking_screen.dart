import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/progress.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/services/step_tracking_service.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';

/// Provider for today's steps
final todayStepsProvider = FutureProvider<int>((ref) async {
  final progressRepo = ref.watch(progressRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return 0;
  }

  return progressRepo.getDailyStepTotal(user.id, DateTime.now());
});

/// Provider for step tracking service
final stepTrackingServiceProvider = Provider<StepTrackingService>((ref) {
  final progressRepo = ref.watch(progressRepositoryProvider);
  return StepTrackingService(progressRepo);
});

/// Provider for step history (last 7 days)
final stepHistoryProvider = FutureProvider<List<StepLog>>((ref) async {
  final progressRepo = ref.watch(progressRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 7));

  return progressRepo.getStepLogs(
    clientId: user.id,
    startDate: startDate,
    endDate: endDate,
  );
});

class StepTrackingScreen extends ConsumerStatefulWidget {
  const StepTrackingScreen({super.key});

  @override
  ConsumerState<StepTrackingScreen> createState() => _StepTrackingScreenState();
}

class _StepTrackingScreenState extends ConsumerState<StepTrackingScreen> {
  final TextEditingController _manualStepsController = TextEditingController();
  bool _isSyncing = false;
  bool _healthAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkHealthAvailability();
  }

  Future<void> _checkHealthAvailability() async {
    final stepService = ref.read(stepTrackingServiceProvider);
    final available = await stepService.isAvailable();
    setState(() {
      _healthAvailable = available;
    });
  }

  Future<void> _syncSteps() async {
    setState(() => _isSyncing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final stepService = ref.read(stepTrackingServiceProvider);
      await stepService.syncTodaySteps(user.id);

      if (mounted) {
        ref.invalidate(todayStepsProvider);
        ref.invalidate(stepHistoryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Steps synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing steps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _addManualSteps() async {
    final stepsText = _manualStepsController.text.trim();
    if (stepsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter number of steps'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final steps = int.tryParse(stepsText);
    if (steps == null || steps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of steps'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final progressRepo = ref.read(progressRepositoryProvider);
      await progressRepo.logSteps(
        clientId: user.id,
        steps: steps,
        source: 'manual',
        date: DateTime.now(),
      );

      if (mounted) {
        _manualStepsController.clear();
        ref.invalidate(todayStepsProvider);
        ref.invalidate(stepHistoryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Steps logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging steps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _manualStepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayStepsAsync = ref.watch(todayStepsProvider);
    final stepHistoryAsync = ref.watch(stepHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Tracking'),
        actions: [
          if (_healthAvailable)
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncSteps,
              tooltip: 'Sync from ${Platform.isIOS ? 'HealthKit' : 'Google Fit'}',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStepsProvider);
          ref.invalidate(stepHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's steps card
              todayStepsAsync.when(
                data: (steps) => _TodayStepsCard(steps: steps),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Error loading steps')),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Manual entry
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Entry',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualStepsController,
                              decoration: const InputDecoration(
                                labelText: 'Steps',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.directions_walk),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _addManualSteps,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Step history chart
              stepHistoryAsync.when(
                data: (logs) => _StepHistoryChart(logs: logs),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStepsCard extends StatelessWidget {
  final int steps;

  const _TodayStepsCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    final goal = 10000; // Default goal, can be made configurable
    final progress = steps / goal;
    final isGoalReached = steps >= goal;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isGoalReached
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Today\'s Steps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              steps.toString(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% of ${goal.toString()} goal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            if (isGoalReached) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Goal Achieved!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepHistoryChart extends StatelessWidget {
  final List<StepLog> logs;

  const _StepHistoryChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Group logs by date
    final Map<DateTime, int> dailySteps = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      dailySteps[dateKey] = 0;
    }

    for (final log in logs) {
      final dateKey = DateTime(log.date.year, log.date.month, log.date.day);
      dailySteps[dateKey] = (dailySteps[dateKey] ?? 0) + log.steps;
    }

    final sortedDates = dailySteps.keys.toList()..sort();
    final maxSteps = dailySteps.values.isEmpty
        ? 10000
        : dailySteps.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSteps * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('E').format(date),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedDates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    final steps = dailySteps[date] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: steps.toDouble(),
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

