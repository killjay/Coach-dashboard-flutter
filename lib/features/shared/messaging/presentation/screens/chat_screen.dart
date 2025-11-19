import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/message.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../widgets/bottom_nav_bar.dart' show bottomNavIconColor;

/// Provider for messages between two users
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, clientId) async* {
  final messageRepo = ref.watch(messageRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role != 'coach') {
    return;
  }

  yield* messageRepo.watchMessages(
    userId1: user.id,
    userId2: clientId,
  );
});

class ChatScreen extends ConsumerStatefulWidget {
  final String clientId; // Can be clientId or coachId depending on user role
  final Conversation? conversation;

  const ChatScreen({
    super.key,
    required this.clientId,
    this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final messageRepo = ref.read(messageRepositoryProvider);

    final message = Message(
      id: '',
      senderId: user.id,
      receiverId: widget.clientId,
      content: content,
      sentAt: DateTime.now(),
      type: MessageType.text,
      coachId: user.role == 'coach' ? user.id : widget.clientId,
      clientId: user.role == 'client' ? user.id : widget.clientId,
      isRead: false,
    );

    try {
      await messageRepo.sendMessage(message);
      _messageController.clear();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    // Determine the other user's ID based on current user's role
    final otherUserId = widget.clientId;
    final messagesAsync = ref.watch(messagesProvider(otherUserId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: bottomNavIconColor.withOpacity(0.1),
              backgroundImage: (user?.role == 'coach'
                      ? widget.conversation?.clientAvatarUrl
                      : widget.conversation?.coachAvatarUrl) != null
                  ? NetworkImage(user?.role == 'coach'
                      ? widget.conversation!.clientAvatarUrl!
                      : widget.conversation!.coachAvatarUrl!)
                  : null,
              child: (user?.role == 'coach'
                      ? widget.conversation?.clientAvatarUrl
                      : widget.conversation?.coachAvatarUrl) == null
                  ? Text(
                      (user?.role == 'coach'
                              ? widget.conversation?.clientName
                              : widget.conversation?.coachName)?[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: bottomNavIconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.role == 'coach'
                        ? (widget.conversation?.clientName ?? 'Client')
                        : (widget.conversation?.coachName ?? 'Coach'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user?.id;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isDark: isDark,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
          _MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: bottomNavIconColor.withOpacity(0.1),
              child: Text(
                'C',
                style: TextStyle(
                  color: bottomNavIconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? bottomNavIconColor
                    : (isDark
                        ? AppTheme.darkSurfaceVariant
                        : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : (isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.textHint),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: bottomNavIconColor.withOpacity(0.1),
              child: Text(
                'Y',
                style: TextStyle(
                  color: bottomNavIconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isDark;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkSurfaceVariant
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkSurfaceVariant
                      : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: bottomNavIconColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

