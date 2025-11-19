import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/message.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../widgets/bottom_nav_bar.dart' show bottomNavIconColor;
import 'chat_screen.dart';

/// Provider for conversations list
final conversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final messageRepo = ref.watch(messageRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return;
  }

  yield* messageRepo.watchConversations(user.id);
});

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with your clients',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationCard(
                conversation: conversation,
                onTap: () {
                  context.push(
                    '/messages/${conversation.clientId}',
                    extra: conversation,
                  );
                },
                isDark: isDark,
              );
            },
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
                'Error loading conversations',
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

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final bool isDark;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.isDark,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
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
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: bottomNavIconColor.withOpacity(0.1),
                  backgroundImage: conversation.clientAvatarUrl != null
                      ? NetworkImage(conversation.clientAvatarUrl!)
                      : null,
                  child: conversation.clientAvatarUrl == null
                      ? Text(
                          conversation.clientName[0].toUpperCase(),
                          style: TextStyle(
                            color: bottomNavIconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            conversation.clientName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (conversation.lastMessage != null)
                            Text(
                              _formatTime(conversation.lastMessage!.sentAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkTextHint
                                        : AppTheme.textHint,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage?.content ?? 'No messages yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((conversation.unreadCount ?? 0) > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: bottomNavIconColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
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

