import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/router.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() =>
      _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        setState(() => _currentIndex = 0);
        break;
      case 1:
        context.go(AppRoutes.clientWorkouts);
        break;
      case 2:
        context.go(AppRoutes.clientWater);
        break;
      case 3:
        context.go(AppRoutes.clientProgress);
        break;
      case 4:
        // TODO: Navigate to profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          // Role switcher for development
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch to Coach View',
            onPressed: () {
              context.go(AppRoutes.coachDashboard);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex.clamp(0, 0), // Only allow index 0 (dashboard)
        children: [
          // Dashboard tab
          _buildDashboardContent(context, user?.name ?? 'Client'),
        ],
      ),
      bottomNavigationBar: ClientBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, String userName) {
    final responsive = Responsive(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        responsive.padding.left,
        responsive.padding.top + 8,
        responsive.padding.right,
        responsive.padding.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: Theme.of(context)
                                      .textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: Theme.of(context)
                                      .textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Track your workouts and progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(32)),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: responsive.spacing(20)),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: responsive.gridColumns,
                crossAxisSpacing: responsive.spacing(16),
                mainAxisSpacing: responsive.spacing(16),
                childAspectRatio: responsive.isMobile ? 1.4 : 1.25,
                children: [
                  _QuickActionCard(
                    icon: Icons.fitness_center,
                    title: 'Workouts',
                    subtitle: 'View workouts',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientWorkouts);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.water_drop,
                    title: 'Water',
                    subtitle: 'Track intake',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientWater);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.trending_up,
                    title: 'Progress',
                    subtitle: 'View progress',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientProgress);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.restaurant_menu,
                    title: 'Meal Plans',
                    subtitle: 'View plans',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientMealPlans);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.message_rounded,
                    title: 'Messages',
                    subtitle: 'Chat with coach',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2596BE), Color(0xFF4FC3F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientMessages);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'View updates',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientNotifications);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Calendar',
                    subtitle: 'Workout schedule',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientWorkoutCalendar);
                    },
                  ),
                  _QuickActionCard(
                    icon: Icons.flag_rounded,
                    title: 'Goals',
                    subtitle: 'Track my goals',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      context.go(AppRoutes.clientGoals);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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


