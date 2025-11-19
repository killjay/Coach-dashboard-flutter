import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/repository_providers.dart';
import '../../../../../../core/repositories/client_repository.dart';
import '../../../../../../core/theme/app_theme.dart';

/// Provider for body composition
final bodyCompositionProvider =
    FutureProvider.family<BodyComposition?, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  return clientRepo.getLatestBodyComposition(clientId);
});

class BodyCompositionTab extends ConsumerWidget {
  final String clientId;

  const BodyCompositionTab({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compositionAsync = ref.watch(bodyCompositionProvider(clientId));

    return compositionAsync.when(
      data: (composition) {
        if (composition == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No body composition data yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Client hasn\'t logged any measurements',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bodyCompositionProvider(clientId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Weight Card
                if (composition.weight != null)
                  _MetricCard(
                    icon: Icons.monitor_weight,
                    title: 'Weight',
                    value: '${composition.weight!.toStringAsFixed(1)} kg',
                    color: AppTheme.primaryColor,
                  ),
                const SizedBox(height: 16),
                // Body Fat Card
                if (composition.bodyFat != null)
                  _MetricCard(
                    icon: Icons.percent,
                    title: 'Body Fat',
                    value: '${composition.bodyFat!.toStringAsFixed(1)}%',
                    color: Colors.orange,
                  ),
                const SizedBox(height: 16),
                // Muscle Mass Card
                if (composition.muscleMass != null)
                  _MetricCard(
                    icon: Icons.fitness_center,
                    title: 'Muscle Mass',
                    value: '${composition.muscleMass!.toStringAsFixed(1)} kg',
                    color: Colors.blue,
                  ),
                if (composition.lastUpdated != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Last updated: ${_formatDate(composition.lastUpdated!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
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
              'Error loading body composition',
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

