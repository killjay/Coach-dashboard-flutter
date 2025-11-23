import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icons.dart';

// Custom color for bottom navigation icons
// RGB: rgba(37, 150, 190) | HSL: 167,67,45 | Hex: #2596BE
const Color bottomNavIconColor = Color.fromRGBO(37, 150, 190, 1.0);

/// Bottom navigation bar for Coach dashboard
class CoachBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CoachBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: currentIndex == 0 ? AppIcons.dashboardFilled : AppIcons.dashboard,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 1 ? AppIcons.workoutFilled : AppIcons.workout,
                label: 'Workouts',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 2 ? AppIcons.clientsFilled : AppIcons.clients,
                label: 'Clients',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 3 ? AppIcons.mealFilled : AppIcons.meal,
                label: 'Meal Plans',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 4 ? AppIcons.profileFilled : AppIcons.profile,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation bar for Client dashboard
class ClientBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ClientBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: currentIndex == 0 ? AppIcons.dashboardFilled : AppIcons.dashboard,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 1 ? AppIcons.workoutFilled : AppIcons.workout,
                label: 'Workouts',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 2 ? AppIcons.waterFilled : AppIcons.water,
                label: 'Water',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 3 ? AppIcons.progressFilled : AppIcons.progress,
                label: 'Progress',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                isDark: isDark,
              ),
              _NavItem(
                icon: currentIndex == 4 ? AppIcons.profileFilled : AppIcons.profile,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: isActive ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? bottomNavIconColor.withOpacity(0.2)
                  : bottomNavIconColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              icon,
              size: 24,
              color: isActive
                  ? (isDark
                      ? bottomNavIconColor
                      : Colors.white)
                  : bottomNavIconColor,
            ),
            if (!isActive) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: bottomNavIconColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
