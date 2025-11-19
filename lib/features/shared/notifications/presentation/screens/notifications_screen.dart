import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/notification.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../widgets/bottom_nav_bar.dart' show bottomNavIconColor;
import 'package:go_router/go_router.dart';

/// Provider for notifications list
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return;
  }

  yield* notificationRepo.watchNotifications(user.id);
});

/// Provider for unread count
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return 0;
  }

  return notificationRepo.getUnreadCount(user.id);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              return IconButton(
                icon: const Icon(Icons.done_all_rounded),
                tooltip: 'Mark all as read',
                onPressed: () async {
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    final notificationRepo = ref.read(notificationRepositoryProvider);
                    await notificationRepo.markAllAsRead(user.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsCountProvider);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () async {
                    final notificationRepo = ref.read(notificationRepositoryProvider);
                    await notificationRepo.markAsRead(notification.id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsCountProvider);
                    
                    // Navigate if action URL is provided
                    if (notification.actionUrl != null) {
                      context.go(notification.actionUrl!);
                    }
                  },
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
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading notifications',
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
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final bool isDark;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.isDark,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.workoutAssigned:
      case NotificationType.workoutReminder:
        return Icons.fitness_center_rounded;
      case NotificationType.mealPlanAssigned:
        return Icons.restaurant_menu_rounded;
      case NotificationType.message:
        return Icons.message_rounded;
      case NotificationType.waterReminder:
        return Icons.water_drop_rounded;
      case NotificationType.progressUpdate:
        return Icons.trending_up_rounded;
      case NotificationType.invoice:
        return Icons.receipt_long_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.workoutAssigned:
      case NotificationType.workoutReminder:
        return const Color(0xFF6366F1);
      case NotificationType.mealPlanAssigned:
        return AppTheme.secondaryColor;
      case NotificationType.message:
        return bottomNavIconColor;
      case NotificationType.waterReminder:
        return Colors.blue;
      case NotificationType.progressUpdate:
        return Colors.green;
      case NotificationType.invoice:
        return Colors.orange;
      case NotificationType.system:
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !(notification.isRead ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark
                ? bottomNavIconColor.withOpacity(0.1)
                : bottomNavIconColor.withOpacity(0.05))
            : (isDark ? AppTheme.darkSurfaceColor : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkSurfaceVariant
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getIconColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: bottomNavIconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.darkTextHint
                                  : AppTheme.textHint,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

