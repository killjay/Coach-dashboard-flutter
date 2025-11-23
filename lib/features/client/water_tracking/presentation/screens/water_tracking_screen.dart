import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/progress.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/repositories/progress_repository.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'water_history_screen.dart';

/// Provider for today's water intake
final dailyWaterProvider = FutureProvider<double>((ref) async {
  final progressRepo = ref.watch(progressRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return 0.0;
  }
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return progressRepo.getDailyWaterTotal(user.id, today);
});

/// Default daily water goal in liters
const double defaultWaterGoal = 2.5; // 2.5 liters = ~8 glasses

class WaterTrackingScreen extends ConsumerWidget {
  const WaterTrackingScreen({super.key});

  Future<void> _logWater(
    BuildContext context,
    WidgetRef ref,
    double amount,
  ) async {
    final progressRepo = ref.read(progressRepositoryProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    try {
      await progressRepo.logWater(
        clientId: user.id,
        amount: amount,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${amount}L of water'),
            duration: const Duration(seconds: 2),
          ),
        );
        ref.invalidate(dailyWaterProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging water: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(dailyWaterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WaterHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: waterAsync.when(
        data: (waterAmount) {
          final percentage = (waterAmount / defaultWaterGoal).clamp(0.0, 1.0);
          final remaining = (defaultWaterGoal - waterAmount).clamp(0.0, double.infinity);

          final responsive = Responsive(context);
          
          return SingleChildScrollView(
            padding: responsive.padding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                child: Column(
                  children: [
                    // Progress Card with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text(
                              'Today\'s Goal',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: responsive.isMobile ? 200 : 250,
                              height: responsive.isMobile ? 200 : 250,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background circle
                                  Container(
                                    width: responsive.isMobile ? 200 : 250,
                                    height: responsive.isMobile ? 200 : 250,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  // Progress circle
                                  SizedBox(
                                    width: responsive.isMobile ? 200 : 250,
                                    height: responsive.isMobile ? 200 : 250,
                                    child: CircularProgressIndicator(
                                      value: percentage,
                                      strokeWidth: 20,
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  // Center content
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${waterAmount.toStringAsFixed(1)}L',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'of ${defaultWaterGoal}L',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (remaining > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${remaining.toStringAsFixed(1)}L remaining',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Goal achieved!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),
                    Text(
                      'Quick Add',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: responsive.gridColumns,
                      crossAxisSpacing: responsive.spacing(16),
                      mainAxisSpacing: responsive.spacing(16),
                      childAspectRatio: responsive.isMobile ? 1.5 : 1.3,
                  children: [
                    _WaterButton(
                      amount: 0.25,
                      label: '250ml\n(1 glass)',
                      icon: Icons.water_drop,
                      onTap: () => _logWater(context, ref, 0.25),
                    ),
                    _WaterButton(
                      amount: 0.5,
                      label: '500ml\n(2 glasses)',
                      icon: Icons.water_drop,
                      onTap: () => _logWater(context, ref, 0.5),
                    ),
                    _WaterButton(
                      amount: 0.75,
                      label: '750ml\n(3 glasses)',
                      icon: Icons.water_drop,
                      onTap: () => _logWater(context, ref, 0.75),
                    ),
                    _WaterButton(
                      amount: 1.0,
                      label: '1L\n(4 glasses)',
                      icon: Icons.water_drop,
                      onTap: () => _logWater(context, ref, 1.0),
                    ),
                  ],
                ),
                    SizedBox(height: responsive.spacing(24)),
                    OutlinedButton.icon(
                      onPressed: () => _showCustomAmountDialog(context, ref),
                      icon: const Icon(Icons.edit),
                      label: const Text('Custom Amount'),
                    ),
                  ],
                ),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(dailyWaterProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showCustomAmountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (Liters)',
            hintText: 'e.g., 0.5',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _logWater(context, ref, amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatefulWidget {
  final double amount;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _WaterButton({
    required this.amount,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_WaterButton> createState() => _WaterButtonState();
}

class _WaterButtonState extends State<_WaterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
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
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

