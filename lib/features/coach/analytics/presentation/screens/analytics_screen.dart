import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/repositories/invoice_repository.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';

/// Provider for current month revenue
final currentMonthRevenueProvider = FutureProvider<MonthlyRevenue>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    throw Exception('User not found or not a coach');
  }

  final now = DateTime.now();
  return invoiceRepo.getMonthlyRevenue(
    coachId: user.id,
    year: now.year,
    month: now.month,
  );
});

/// Provider for upcoming months revenue
final upcomingMonthsRevenueProvider = FutureProvider<List<MonthlyRevenue>>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    throw Exception('User not found or not a coach');
  }

  return invoiceRepo.getUpcomingMonthsRevenue(
    coachId: user.id,
    monthsAhead: 6,
  );
});

/// Provider for last 6 months revenue
final last6MonthsRevenueProvider = FutureProvider<List<MonthlyRevenue>>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    throw Exception('User not found or not a coach');
  }

  final now = DateTime.now();
  final results = <MonthlyRevenue>[];

  for (int i = 5; i >= 0; i--) {
    final targetDate = DateTime(now.year, now.month - i, 1);
    final revenue = await invoiceRepo.getMonthlyRevenue(
      coachId: user.id,
      year: targetDate.year,
      month: targetDate.month,
    );
    results.add(revenue);
  }

  return results;
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonthAsync = ref.watch(currentMonthRevenueProvider);
    final last6MonthsAsync = ref.watch(last6MonthsRevenueProvider);
    final upcomingMonthsAsync = ref.watch(upcomingMonthsRevenueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Performance'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentMonthRevenueProvider);
          ref.invalidate(last6MonthsRevenueProvider);
          ref.invalidate(upcomingMonthsRevenueProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Month Summary
              currentMonthAsync.when(
                data: (revenue) => _CurrentMonthCard(revenue: revenue),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Last 6 Months Chart
              Text(
                'Revenue Trend (Last 6 Months)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              last6MonthsAsync.when(
                data: (revenues) => _RevenueChart(revenues: revenues),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $error'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Upcoming Months Forecast
              Text(
                'Upcoming Months Forecast',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              upcomingMonthsAsync.when(
                data: (revenues) => _UpcomingMonthsList(revenues: revenues),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentMonthCard extends StatelessWidget {
  final MonthlyRevenue revenue;

  const _CurrentMonthCard({required this.revenue});

  String _getMonthName() {
    return DateFormat('MMMM yyyy').format(DateTime(revenue.year, revenue.month));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMonthName(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${revenue.totalRevenue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Invoices',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${revenue.invoiceCount}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Paid',
                  value: '${revenue.paidInvoices}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  label: 'Pending',
                  value: '${revenue.pendingInvoices}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  label: 'Avg Value',
                  value: '\$${revenue.averageInvoiceValue.toStringAsFixed(0)}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<MonthlyRevenue> revenues;

  const _RevenueChart({required this.revenues});

  String _getMonthLabel(MonthlyRevenue revenue) {
    return DateFormat('MMM').format(DateTime(revenue.year, revenue.month));
  }

  @override
  Widget build(BuildContext context) {
    if (revenues.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    final maxRevenue = revenues
        .map((r) => r.totalRevenue)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRevenue * 1.2,
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
                      final index = value.toInt();
                      if (index >= 0 && index < revenues.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getMonthLabel(revenues[index]),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
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
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${(value / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
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
                horizontalInterval: maxRevenue / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: revenues.asMap().entries.map((entry) {
                final index = entry.key;
                final revenue = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: revenue.totalRevenue,
                      color: AppTheme.primaryColor,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingMonthsList extends StatelessWidget {
  final List<MonthlyRevenue> revenues;

  const _UpcomingMonthsList({required this.revenues});

  String _getMonthName(MonthlyRevenue revenue) {
    return DateFormat('MMMM yyyy').format(DateTime(revenue.year, revenue.month));
  }

  @override
  Widget build(BuildContext context) {
    if (revenues.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No forecast data available')),
        ),
      );
    }

    return Column(
      children: revenues.map((revenue) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMonthName(revenue),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${revenue.invoiceCount} invoices • ${revenue.paidInvoices} paid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${revenue.totalRevenue.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

