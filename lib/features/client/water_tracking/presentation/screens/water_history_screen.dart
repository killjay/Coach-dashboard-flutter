import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/progress.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/repositories/progress_repository.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for water history
final waterHistoryProvider = FutureProvider<List<WaterLog>>((ref) async {
  final progressRepo = ref.watch(progressRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return [];
  }
  
  // Get last 30 days of water logs
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 30));
  
  return progressRepo.getWaterLogs(
    clientId: user.id,
    startDate: startDate,
    endDate: endDate,
  );
});

/// Water History Screen following Apple HIG principles:
/// - Clarity: Clear chronological organization
/// - Deference: Content-first with minimal UI chrome
/// - Depth: Subtle visual hierarchy
class WaterHistoryScreen extends ConsumerWidget {
  const WaterHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterHistoryAsync = ref.watch(waterHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Water History'),
      ),
      body: waterHistoryAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 64,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No water logs yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your water intake to see your history here',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group logs by date
          final groupedLogs = <DateTime, List<WaterLog>>{};
          for (final log in logs) {
            final date = DateTime(
              log.date.year,
              log.date.month,
              log.date.day,
            );
            groupedLogs.putIfAbsent(date, () => []).add(log);
          }

          final sortedDates = groupedLogs.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(waterHistoryProvider);
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.padding.left,
                vertical: responsive.padding.top,
              ),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dayLogs = groupedLogs[date]!;
                final dayTotal = dayLogs.fold<double>(
                  0.0,
                  (sum, log) => sum + log.amount,
                );
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return _WaterHistoryDayCard(
                  date: date,
                  logs: dayLogs,
                  total: dayTotal,
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
                'Error loading history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(waterHistoryProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Water History Day Card - Apple HIG: Clear grouping with depth
class _WaterHistoryDayCard extends StatelessWidget {
  final DateTime date;
  final List<WaterLog> logs;
  final double total;
  final bool isToday;
  final bool isDark;

  const _WaterHistoryDayCard({
    required this.date,
    required this.logs,
    required this.total,
    required this.isToday,
    required this.isDark,
  });

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
                      '${logs.length} ${logs.length == 1 ? 'entry' : 'entries'}',
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
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${total.toStringAsFixed(1)}L',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Logs list
          ...logs.map((log) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${log.amount.toStringAsFixed(2)}L',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Text(
                    timeFormat.format(log.loggedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
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

