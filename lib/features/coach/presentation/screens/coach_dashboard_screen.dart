import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/router.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../shared/widgets/bottom_nav_bar.dart' show bottomNavIconColor, CoachBottomNavBar;
import '../widgets/sales_analytics_card.dart';
import '../../clients/presentation/screens/client_list_screen.dart' show clientListProvider;
import '../../../shared/notifications/presentation/screens/notifications_screen.dart' show unreadNotificationsCountProvider;

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentIndex = 0);
        break;
      case 1:
        context.go(AppRoutes.coachWorkouts);
        break;
      case 2:
        context.go(AppRoutes.clients);
        break;
      case 3:
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _MealPlanOptionsSheet(),
        );
        break;
      case 4:
        // TODO: Navigate to profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Notifications
          Consumer(
            builder: (context, ref, _) {
              final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () {
                      context.push(AppRoutes.notifications);
                    },
                  ),
                  unreadCountAsync.when(
                    data: (count) {
                      if (count > 0) {
                        return Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
          // Dark mode toggle
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeModeProvider);
              final isDarkMode = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark);

              return IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              );
            },
          ),
          // Role switcher for development
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch to Client View',
            onPressed: () {
              context.go(AppRoutes.clientDashboard);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex.clamp(0, 0),
        children: [
          _buildDashboardContent(context, user?.name ?? 'Coach', isDark),
        ],
      ),
      bottomNavigationBar: CoachBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, String userName, bool isDark) {
    final responsive = Responsive(context);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh sales data
        ref.invalidate(dailySalesProvider);
        ref.invalidate(monthlySalesProvider);
        ref.invalidate(yearToDateSalesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          responsive.padding.left,
          responsive.padding.top + 8,
          responsive.padding.right,
          responsive.padding.bottom + 80, // Space for bottom nav
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales Analytics Card
                const SalesAnalyticsCard()
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideY(begin: -0.1, end: 0, duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 24),

                // Client Management Section
                Text(
                  'Client Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 16),

                // Add Client & View Clients Cards
                Row(
                  children: [
                    Expanded(
                      child: _ModernActionCard(
                        icon: Icons.person_add_rounded,
                        title: 'Add New Client',
                        subtitle: 'Onboard a new client',
                        color: AppTheme.secondaryColor,
                        onTap: () {
                          context.push(AppRoutes.addClient);
                        },
                        isDark: isDark,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1),
                              duration: 400.ms, delay: 300.ms),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ModernActionCard(
                        icon: Icons.people_rounded,
                        title: 'View All Clients',
                        subtitle: '${ref.watch(clientListProvider).when(
                              data: (clients) => '${clients.length} clients',
                              loading: () => 'Loading...',
                              error: (_, __) => 'View clients',
                            )}',
                        color: AppTheme.primaryColor,
                        onTap: () {
                          context.go(AppRoutes.clients);
                        },
                        isDark: isDark,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms)
                          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1),
                              duration: 400.ms, delay: 400.ms),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Quick Actions Section
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideX(begin: -0.1, end: 0, duration: 400.ms, delay: 500.ms),
                const SizedBox(height: 16),

                // Quick Actions Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: responsive.isMobile ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: responsive.isMobile ? 1.3 : 1.2,
                  children: [
                    _ModernActionCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Workouts',
                      subtitle: 'Manage workouts',
                      color: const Color(0xFF6366F1),
                      onTap: () => context.go(AppRoutes.coachWorkouts),
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 600.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
                            duration: 400.ms, delay: 600.ms),
                    _ModernActionCard(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Meal Plans',
                      subtitle: 'Ingredients & videos',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => _MealPlanOptionsSheet(),
                        );
                      },
                      isDark: isDark,
                    ),
                    _ModernActionCard(
                      icon: Icons.message_rounded,
                      title: 'Messages',
                      subtitle: 'Chat with clients',
                      color: bottomNavIconColor,
                      onTap: () => context.go(AppRoutes.messages),
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 700.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
                            duration: 400.ms, delay: 700.ms),
                    _ModernActionCard(
                      icon: Icons.analytics_rounded,
                      title: 'Analytics',
                      subtitle: 'View insights',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.go(AppRoutes.analytics),
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 800.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
                            duration: 400.ms, delay: 800.ms),
                    _ModernActionCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Invoices',
                      subtitle: 'Manage invoices',
                      color: const Color(0xFFEC4899),
                      onTap: () => context.go(AppRoutes.invoices),
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 900.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
                            duration: 400.ms, delay: 900.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_ModernActionCard> createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<_ModernActionCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppTheme.darkSurfaceColor
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark
                  ? AppTheme.darkSurfaceVariant
                  : widget.color.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withOpacity(0.3)
                    : widget.color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealPlanOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Meal Plans',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.restaurant_rounded,
                color: AppTheme.secondaryColor),
            title: const Text('Ingredients'),
            subtitle: const Text('Manage ingredients with nutritional info'),
            onTap: () {
              Navigator.pop(context);
              context.go('/coach/meal-plans/ingredients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library_rounded,
                color: AppTheme.primaryColor),
            title: const Text('Cooking Videos'),
            subtitle: const Text('Add and manage cooking videos'),
            onTap: () {
              Navigator.pop(context);
              context.go('/coach/meal-plans/videos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_rounded,
                color: AppTheme.accentColor),
            title: const Text('Assign Meal Plan'),
            subtitle: const Text('Assign meal plans to clients'),
            onTap: () {
              Navigator.pop(context);
              context.go('/coach/meal-plans/assign');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
