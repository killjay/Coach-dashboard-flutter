import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../../core/models/progress.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/repositories/progress_repository.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for today's water intake with optimistic updates
final dailyWaterProvider = StateNotifierProvider<DailyWaterNotifier, AsyncValue<double>>((ref) {
  return DailyWaterNotifier(ref);
});

class DailyWaterNotifier extends StateNotifier<AsyncValue<double>> {
  final Ref _ref;
  DateTime? _lastLoadedDate;
  double? _cachedValue;
  
  DailyWaterNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadWater();
  }
  
  Future<void> _loadWater() async {
    try {
      final progressRepo = _ref.read(progressRepositoryProvider);
      final user = _ref.read(currentUserProvider);
      
      if (user == null) {
        state = const AsyncValue.data(0.0);
        return;
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Use cache if we already loaded today's data
      if (_lastLoadedDate != null && 
          _lastLoadedDate!.year == today.year &&
          _lastLoadedDate!.month == today.month &&
          _lastLoadedDate!.day == today.day &&
          _cachedValue != null) {
        state = AsyncValue.data(_cachedValue!);
        return;
      }
      
      // Optimize: Get today's logs directly instead of using getDailyWaterTotal
      // which makes a separate query
      final startOfDay = today;
      final endOfDay = today.add(const Duration(days: 1));
      
      final logs = await progressRepo.getWaterLogs(
        clientId: user.id,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      double total = 0.0;
      for (final log in logs) {
        total += log.amount;
      }
      
      _cachedValue = total;
      _lastLoadedDate = today;
      state = AsyncValue.data(total);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> addWater(double amount) async {
    final currentValue = state.valueOrNull ?? 0.0;
    final newValue = currentValue + amount;
    
    // Optimistically update UI immediately
    state = AsyncValue.data(newValue);
    _cachedValue = newValue;
    
    // Also update weekly chart optimistically
    _ref.read(weeklyWaterProvider.notifier).addWaterToToday(amount);
    
    // Then sync with backend
    try {
      final progressRepo = _ref.read(progressRepositoryProvider);
      final user = _ref.read(currentUserProvider);
      
      if (user == null) {
        return;
      }
      
      await progressRepo.logWater(
        clientId: user.id,
        amount: amount,
      );
      
      // Update cache immediately without delay
      _cachedValue = newValue;
      
      // Reload in background (non-blocking)
      _loadWater().then((_) {
        _ref.read(weeklyWaterProvider.notifier).refresh();
      });
    } catch (e, stack) {
      // Revert optimistic update on error
      state = AsyncValue.data(currentValue);
      _cachedValue = currentValue;
      // Revert weekly chart update
      await _ref.read(weeklyWaterProvider.notifier).refresh();
      rethrow;
    }
  }
  
  void refresh() {
    _loadWater();
  }
}

/// Provider for weekly water intake (last 7 days) with optimistic updates
final weeklyWaterProvider = StateNotifierProvider<WeeklyWaterNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return WeeklyWaterNotifier(ref);
});

class WeeklyWaterNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  DateTime? _lastLoadedDate;
  List<Map<String, dynamic>>? _cachedData;
  
  WeeklyWaterNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadWeeklyData();
  }
  
  Future<void> _loadWeeklyData() async {
    try {
      final progressRepo = _ref.read(progressRepositoryProvider);
      final user = _ref.read(currentUserProvider);
      
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Use cache if we already loaded today's data
      if (_lastLoadedDate != null && 
          _lastLoadedDate!.year == today.year &&
          _lastLoadedDate!.month == today.month &&
          _lastLoadedDate!.day == today.day &&
          _cachedData != null) {
        state = AsyncValue.data(_cachedData!);
        return;
      }
      
      final startDate = today.subtract(const Duration(days: 6));
      final endDate = today.add(const Duration(days: 1));
      
      // Single query to get all water logs for the week (much faster than 7 separate queries)
      final allLogs = await progressRepo.getWaterLogs(
        clientId: user.id,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Group logs by date and calculate totals
      final dailyTotals = <DateTime, double>{};
      for (final log in allLogs) {
        final logDate = DateTime(
          log.date.year,
          log.date.month,
          log.date.day,
        );
        dailyTotals[logDate] = (dailyTotals[logDate] ?? 0.0) + log.amount;
      }
      
      // Build weekly data array
      final List<Map<String, dynamic>> weeklyData = [];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final total = dailyTotals[date] ?? 0.0;
        final isGoalMet = total >= defaultWaterGoal;
        
        weeklyData.add({
          'date': date,
          'total': total,
          'isGoalMet': isGoalMet,
        });
      }
      
      _cachedData = weeklyData;
      _lastLoadedDate = today;
      state = AsyncValue.data(weeklyData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  void addWaterToToday(double amount) {
    final currentData = state.valueOrNull;
    if (currentData == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Update today's data optimistically
    final updatedData = currentData.map((dayData) {
      final date = dayData['date'] as DateTime;
      if (date.year == today.year && 
          date.month == today.month && 
          date.day == today.day) {
        final newTotal = (dayData['total'] as double) + amount;
        return {
          'date': date,
          'total': newTotal,
          'isGoalMet': newTotal >= defaultWaterGoal,
        };
      }
      return dayData;
    }).toList();
    
    _cachedData = updatedData;
    state = AsyncValue.data(updatedData);
  }
  
  Future<void> refresh() async {
    // Clear cache to force reload
    _lastLoadedDate = null;
    _cachedData = null;
    await _loadWeeklyData();
  }
}

/// Default daily water goal in liters
const double defaultWaterGoal = 2.5; // 2.5 liters = ~8 glasses

class WaterTrackingScreen extends ConsumerWidget {
  const WaterTrackingScreen({super.key});

  Future<void> _logWater(
    BuildContext context,
    WidgetRef ref,
    double amount,
  ) async {
    try {
      // Use the StateNotifier to add water (optimistic update)
      // This will update both daily and weekly charts immediately
      await ref.read(dailyWaterProvider.notifier).addWater(amount);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Added ${(amount * 1000).toInt()}ml'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging water: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterAsync = ref.watch(dailyWaterProvider);
    final weeklyAsync = ref.watch(weeklyWaterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? AppTheme.darkBackgroundColor 
          : const Color(0xFFF0F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: Container(
        decoration: isDark
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkBackgroundColor,
                    const Color(0xFF0A0A0A),
                  ],
                ),
              )
            : null,
        child: ref.watch(dailyWaterProvider).when(
        data: (waterAmount) {
          final percentage = (waterAmount / defaultWaterGoal).clamp(0.0, 1.0);
          final remaining = (defaultWaterGoal - waterAmount).clamp(0.0, double.infinity);
          final isGoalMet = waterAmount >= defaultWaterGoal;

          final responsive = Responsive(context);
          
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.padding.left,
              vertical: responsive.padding.top,
            ),
            child: Column(
              children: [
                // Liquid Wave Progress Indicator
                _LiquidWaveProgress(
                  percentage: percentage,
                  currentAmount: waterAmount,
                  goalAmount: defaultWaterGoal,
                  isGoalMet: isGoalMet,
                ),
                SizedBox(height: responsive.spacing(32)),
                
                // Quick Add Section
                Text(
                  'Quick Add',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0C4A6E),
                      ),
                ),
                SizedBox(height: responsive.spacing(20)),
                
                // Quick Add Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickAddButton(
                      amount: 0.25,
                      label: 'Glass',
                      icon: Icons.wine_bar_rounded,
                      color: const Color(0xFF06B6D4),
                      onTap: () => _logWater(context, ref, 0.25),
                    ),
                    _QuickAddButton(
                      amount: 0.5,
                      label: 'Bottle',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF0891B2),
                      onTap: () => _logWater(context, ref, 0.5),
                    ),
                    _QuickAddButton(
                      amount: 0.75,
                      label: 'Large',
                      icon: Icons.local_drink_rounded,
                      color: const Color(0xFF0E7490),
                      onTap: () => _logWater(context, ref, 0.75),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(24)),
                
                // Custom Amount Button
                OutlinedButton.icon(
                  onPressed: () => _showCustomAmountDialog(context, ref),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Custom Amount'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6D4),
                    side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(32)),
                
                // Weekly Chart Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0C4A6E),
                            ),
                      ),
                      SizedBox(height: responsive.spacing(20)),
                      ref.watch(weeklyWaterProvider).when(
                        data: (weeklyData) => _WeeklyChart(
                          data: weeklyData,
                          goal: defaultWaterGoal,
                          isDark: isDark,
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (_, __) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('Error loading weekly data'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),
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
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Custom Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (Liters)',
            hintText: 'e.g., 0.5',
            prefixIcon: const Icon(Icons.water_drop_rounded),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Animated Liquid Wave Progress Indicator
class _LiquidWaveProgress extends StatefulWidget {
  final double percentage;
  final double currentAmount;
  final double goalAmount;
  final bool isGoalMet;

  const _LiquidWaveProgress({
    required this.percentage,
    required this.currentAmount,
    required this.goalAmount,
    required this.isGoalMet,
  });

  @override
  State<_LiquidWaveProgress> createState() => _LiquidWaveProgressState();
}

class _LiquidWaveProgressState extends State<_LiquidWaveProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 280.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE0F2FE),
            const Color(0xFFBAE6FD),
            const Color(0xFF7DD3FC),
          ],
        ),
        boxShadow: widget.isGoalMet
            ? [
                // Glow effect when goal is met
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Liquid wave
          ClipOval(
            child: CustomPaint(
              size: Size(size, size),
              painter: _LiquidWavePainter(
                percentage: widget.percentage,
                animation: _waveController,
                isGoalMet: widget.isGoalMet,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(
                  begin: 0,
                  end: (widget.currentAmount * 1000).toInt(),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '$value',
                    style: TextStyle(
                      fontSize: widget.isGoalMet ? 56 : 48,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0C4A6E),
                      shadows: widget.isGoalMet
                          ? [
                              Shadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              ),
              Text(
                'ml',
                style: TextStyle(
                  fontSize: widget.isGoalMet ? 24 : 20,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'of ${(widget.goalAmount * 1000).toInt()}ml goal',
                  style: TextStyle(
                    fontSize: widget.isGoalMet ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B).withOpacity(widget.isGoalMet ? 0.6 : 1.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for Liquid Wave Effect
class _LiquidWavePainter extends CustomPainter {
  final double percentage;
  final Animation<double> animation;
  final bool isGoalMet;

  _LiquidWavePainter({
    required this.percentage,
    required this.animation,
    required this.isGoalMet,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isGoalMet
            ? [
                const Color(0xFF10B981),
                const Color(0xFF34D399),
              ]
            : [
                const Color(0xFF06B6D4),
                const Color(0xFF22D3EE),
                const Color(0xFF67E8F9),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Calculate water level (from bottom)
    final waterLevel = size.height * (1 - percentage);
    
    // Create wave path
    final path = Path();
    path.moveTo(0, waterLevel);
    
    // Wave animation
    final waveOffset = animation.value * 2 * math.pi;
    final waveAmplitude = 8.0;
    final waveFrequency = 0.02;
    
    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel + math.sin((x * waveFrequency) + waveOffset) * waveAmplitude;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Add subtle highlight
    final highlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.3);
    
    final highlightPath = Path();
    highlightPath.moveTo(0, waterLevel);
    
    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel + math.sin((x * waveFrequency) + waveOffset) * waveAmplitude - 2;
      highlightPath.lineTo(x, y);
    }
    
    highlightPath.lineTo(size.width, waterLevel + 20);
    highlightPath.lineTo(0, waterLevel + 20);
    highlightPath.close();
    
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(_LiquidWavePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.animation.value != animation.value ||
        oldDelegate.isGoalMet != isGoalMet;
  }
}

/// Quick Add Button
class _QuickAddButton extends StatefulWidget {
  final double amount;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.amount,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        // Haptic feedback on tap
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '+${(widget.amount * 1000).toInt()}ml',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weekly Chart Widget
class _WeeklyChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final double goal;
  final bool isDark;

  const _WeeklyChart({
    required this.data,
    required this.goal,
    required this.isDark,
  });

  @override
  State<_WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<_WeeklyChart> {
  int? _hoveredIndex;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No data available'),
        ),
      );
    }

    final maxValue = widget.data.map((d) => d['total'] as double).reduce(math.max);
    final chartHeight = 220.0; // Increased to accommodate tooltip
    final spacing = 8.0;
    final tooltipHeight = 40.0; // Space reserved for tooltip

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.data.asMap().entries.map((entry) {
              final index = entry.key;
              final dayData = entry.value;
              final date = dayData['date'] as DateTime;
              final total = dayData['total'] as double;
              final isGoalMet = dayData['isGoalMet'] as bool;
              final dayName = DateFormat('E').format(date).substring(0, 1);
              final dayNumber = date.day.toString();
              
              // Calculate available height for bars (accounting for tooltip, labels, and spacing)
              final availableHeight = chartHeight - tooltipHeight - 50; // 50 for labels and spacing
              final targetBarHeight = maxValue > 0 ? (total / maxValue) * availableHeight : 0.0;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final isHovered = _hoveredIndex == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _hoveredIndex = _hoveredIndex == index ? null : index;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Tooltip on hover/tap - using SizedBox to reserve space
                        SizedBox(
                          height: isHovered ? tooltipHeight : 0,
                          child: AnimatedOpacity(
                            opacity: isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: isHovered
                                ? Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: widget.isDark ? AppTheme.darkSurfaceColor : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${(total * 1000).toInt()}ml${isGoalMet ? ' ✓' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDark ? AppTheme.darkTextPrimary : const Color(0xFF0C4A6E),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        // Animated bar
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: targetBarHeight),
                          duration: Duration(milliseconds: 600 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedHeight, child) {
                            return AnimatedScale(
                              scale: isHovered ? 1.05 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Tooltip(
                                message: '${(total * 1000).toInt()}ml${isGoalMet ? ' ✓' : ''}',
                                child: Container(
                                  height: animatedHeight.clamp(4.0, availableHeight),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: isGoalMet
                                          ? [
                                              // Brighter, more vibrant green for goal met
                                              const Color(0xFF059669),
                                              const Color(0xFF10B981),
                                              const Color(0xFF34D399),
                                            ]
                                          : [
                                              // More subdued blue for in progress
                                              const Color(0xFF0891B2).withOpacity(0.7),
                                              const Color(0xFF06B6D4).withOpacity(0.8),
                                              const Color(0xFF22D3EE).withOpacity(0.9),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isGoalMet
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF06B6D4))
                                            .withOpacity(isHovered ? 0.5 : 0.3),
                                        blurRadius: isHovered ? 12 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Day label with date number
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: isToday ? 13 : 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                color: isToday
                                    ? const Color(0xFF06B6D4)
                                    : (widget.isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayNumber,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                color: isToday
                                    ? const Color(0xFF06B6D4).withOpacity(0.8)
                                    : (widget.isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        if (isGoalMet) ...[
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                        ] else ...[
                          const SizedBox(height: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: const Color(0xFF06B6D4),
              label: 'In Progress',
              isDark: widget.isDark,
            ),
            const SizedBox(width: 24),
            _LegendItem(
              color: const Color(0xFF10B981),
              label: 'Goal Met',
              isDark: widget.isDark,
            ),
          ],
        ),
      ],
    );
  }
}

/// Legend Item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
