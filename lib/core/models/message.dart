import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Message model for coach-client communication
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String senderId,
    required String receiverId,
    required String content,
    required DateTime sentAt,
    required MessageType type,
    String? coachId,
    String? clientId,
    String? attachmentUrl,
    String? attachmentType, // 'image', 'pdf', 'video', etc.
    bool? isRead,
    DateTime? readAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// Message type enum
@JsonEnum()
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('file')
  file,
  @JsonValue('system')
  system,
}

/// Conversation model
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String coachId,
    required String clientId,
    required String clientName,
    String? clientAvatarUrl,
    required String coachName,
    String? coachAvatarUrl,
    Message? lastMessage,
    required DateTime updatedAt,
    int? unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

