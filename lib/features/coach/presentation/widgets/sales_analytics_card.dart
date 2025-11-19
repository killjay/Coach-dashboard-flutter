import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/invoice_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Provider for hourly sales data (with dummy data for now)
final hourlySalesProvider = FutureProvider<List<HourlySale>>((ref) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Generate dummy data for today's hourly sales
  final now = DateTime.now();
  final hourlySales = <HourlySale>[];
  
  // Generate sales for each hour from 8 AM to 8 PM
  for (int hour = 8; hour <= 20; hour++) {
    // Create some variation in sales (higher during business hours)
    double baseAmount = 150.0;
    if (hour >= 9 && hour <= 12) {
      // Morning peak
      baseAmount = 250.0 + (hour - 9) * 30.0;
    } else if (hour >= 13 && hour <= 17) {
      // Afternoon peak
      baseAmount = 300.0 - (hour - 13) * 20.0;
    } else if (hour >= 18 && hour <= 20) {
      // Evening
      baseAmount = 180.0 - (hour - 18) * 15.0;
    }
    
    // Add some randomness
    final random = (hour * 7 + now.day) % 50;
    final amount = baseAmount + random;
    
    hourlySales.add(HourlySale(
      hour: hour,
      amount: amount,
    ));
  }
  
  return hourlySales;
});

/// Provider for daily sales (sum of hourly sales)
final dailySalesProvider = FutureProvider<double>((ref) async {
  final hourlySales = await ref.watch(hourlySalesProvider.future);
  return hourlySales.fold<double>(0.0, (sum, sale) => sum + sale.amount);
});

/// Hourly sale model
class HourlySale {
  final int hour;
  final double amount;

  HourlySale({
    required this.hour,
    required this.amount,
  });
}

/// Provider for monthly sales
final monthlySalesProvider = FutureProvider<double>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return 0.0;
  }

  final now = DateTime.now();
  final revenue = await invoiceRepo.getMonthlyRevenue(
    coachId: user.id,
    year: now.year,
    month: now.month,
  );

  return revenue.totalRevenue;
});

/// Provider for year-to-date sales
final yearToDateSalesProvider = FutureProvider<double>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return 0.0;
  }

  final now = DateTime.now();
  double total = 0.0;

  // Sum all months from January to current month
  for (int month = 1; month <= now.month; month++) {
    final revenue = await invoiceRepo.getMonthlyRevenue(
      coachId: user.id,
      year: now.year,
      month: month,
    );
    total += revenue.totalRevenue;
  }

  return total;
});

class SalesAnalyticsCard extends ConsumerWidget {
  const SalesAnalyticsCard({super.key});

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(2)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyAsync = ref.watch(dailySalesProvider);
    final monthlyAsync = ref.watch(monthlySalesProvider);
    final ytdAsync = ref.watch(yearToDateSalesProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1C1C1E),
                  const Color(0xFF2C2C2E),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Sales',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM yyyy').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextHint
                                    : AppTheme.textHint,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Today's Sales Chart
            _TodaySalesChart(isDark: isDark),
            const SizedBox(height: 32),
            // Sales metrics
            Row(
              children: [
                Expanded(
                  child: _SalesMetric(
                    label: 'Today',
                    value: dailyAsync.when(
                      data: (value) => _formatCurrency(value),
                      loading: () => '...',
                      error: (_, __) => '\$0.00',
                    ),
                    icon: Icons.calendar_today_rounded,
                    color: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SalesMetric(
                    label: 'This Month',
                    value: monthlyAsync.when(
                      data: (value) => _formatCurrency(value),
                      loading: () => '...',
                      error: (_, __) => '\$0.00',
                    ),
                    icon: Icons.calendar_month_rounded,
                    color: AppTheme.secondaryColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SalesMetric(
                    label: 'Year to Date',
                    value: ytdAsync.when(
                      data: (value) => _formatCurrency(value),
                      loading: () => '...',
                      error: (_, __) => '\$0.00',
                    ),
                    icon: Icons.date_range_rounded,
                    color: AppTheme.accentColor,
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

class _SalesMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SalesMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurfaceVariant.withOpacity(0.5)
            : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkSurfaceVariant
              : color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _TodaySalesChart extends ConsumerWidget {
  final bool isDark;

  const _TodaySalesChart({required this.isDark});

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlySalesAsync = ref.watch(hourlySalesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurfaceVariant.withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkSurfaceVariant
              : AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Sales by Hour',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          hourlySalesAsync.when(
            data: (hourlySales) {
              if (hourlySales.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('No data available')),
                );
              }

              final maxAmount = hourlySales
                  .map((sale) => sale.amount)
                  .reduce((a, b) => a > b ? a : b);

              return SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAmount * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipBgColor: isDark
                            ? AppTheme.darkSurfaceColor
                            : Colors.white,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '\$${rod.toY.toStringAsFixed(2)}',
                            TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < hourlySales.length) {
                              final hour = hourlySales[index].hour;
                              // Show every 2 hours to avoid crowding
                              if (hour % 2 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _formatHour(hour),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '\$${(value / 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxAmount / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark
                              ? AppTheme.darkSurfaceVariant
                              : Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: hourlySales.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sale = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: sale.amount,
                            color: AppTheme.primaryColor,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxAmount * 1.2,
                              color: isDark
                                  ? AppTheme.darkSurfaceVariant.withOpacity(0.3)
                                  : AppTheme.primaryColor.withOpacity(0.05),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Error loading chart',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

