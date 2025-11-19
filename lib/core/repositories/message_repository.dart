import '../models/message.dart';

/// Abstract repository interface for messaging
abstract class MessageRepository {
  /// Send a message
  Future<Message> sendMessage(Message message);

  /// Get messages between two users
  Future<List<Message>> getMessages({
    required String userId1,
    required String userId2,
  });

  /// Get conversations for a user
  Future<List<Conversation>> getConversations(String userId);

  /// Mark messages as read
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  });

  /// Watch messages in real-time
  Stream<List<Message>> watchMessages({
    required String userId1,
    required String userId2,
  });

  /// Watch conversations in real-time
  Stream<List<Conversation>> watchConversations(String userId);

  /// Delete a message
  Future<void> deleteMessage(String messageId);

  /// Upload attachment
  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    required String conversationId,
  });
}

