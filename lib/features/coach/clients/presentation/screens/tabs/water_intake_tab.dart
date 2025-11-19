import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/models/progress.dart';
import '../../../../../../core/providers/repository_providers.dart';
import '../../../../../../core/repositories/client_repository.dart';
import '../../../../../../core/theme/app_theme.dart';

/// Provider for water logs
final waterLogsProvider =
    FutureProvider.family<List<WaterLog>, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, now.day - 30);
  return clientRepo.getClientWaterLogs(
    clientId: clientId,
    startDate: startDate,
  );
});

class WaterIntakeTab extends ConsumerWidget {
  final String clientId;

  const WaterIntakeTab({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(waterLogsProvider(clientId));

    return waterAsync.when(
      data: (waterLogs) {
        if (waterLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No water intake data yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Client hasn\'t logged any water intake',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        // Group by date and calculate daily totals
        final dailyTotals = <DateTime, double>{};
        for (final log in waterLogs) {
          final date = DateTime(log.date.year, log.date.month, log.date.day);
          dailyTotals[date] = (dailyTotals[date] ?? 0) + log.amount;
        }

        final sortedDates = dailyTotals.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        final totalWater = waterLogs.fold<double>(
            0, (sum, log) => sum + log.amount);
        final averageWater = dailyTotals.isNotEmpty
            ? dailyTotals.values.reduce((a, b) => a + b) / dailyTotals.length
            : 0.0;
        final todayWater = dailyTotals[DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day)] ??
            0.0;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(waterLogsProvider(clientId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Today',
                        value: '${todayWater.toStringAsFixed(1)}L',
                        subtitle: 'water',
                        color: Colors.cyan,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Average',
                        value: '${averageWater.toStringAsFixed(1)}L',
                        subtitle: 'per day',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Daily Intake (Last 30 Days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...sortedDates.take(30).map((date) => _WaterLogCard(
                      date: date,
                      amount: dailyTotals[date]!,
                    )),
              ],
            ),
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
              'Error loading water data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterLogCard extends StatelessWidget {
  final DateTime date;
  final double amount;

  const _WaterLogCard({
    required this.date,
    required this.amount,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return 'Today';
    } else if (logDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(1)}L',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
          ),
        ],
      ),
    );
  }
}

