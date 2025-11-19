import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import '../models/message.dart';
import '../repositories/message_repository.dart';
import 'firebase_user_service.dart';

/// Firebase implementation of MessageRepository
class FirebaseMessageService implements MessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseUserService _userService = FirebaseUserService();

  @override
  Future<Message> sendMessage(Message message) async {
    try {
      final docRef = _firestore.collection('messages').doc();

      final messageData = message.toJson();
      messageData.remove('id');

      await docRef.set({
        ...messageData,
        'sentAt': FieldValue.serverTimestamp(),
      });

      // Update conversation
      await _updateConversation(message);

      return message.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> _updateConversation(Message message) async {
    try {
      final conversationId = _getConversationId(message.coachId!, message.clientId!);
      final conversationRef = _firestore.collection('conversations').doc(conversationId);

      // Get user names
      final coach = await _userService.getUser(message.coachId!);
      final client = await _userService.getUser(message.clientId!);

      await conversationRef.set({
        'id': conversationId,
        'coachId': message.coachId,
        'clientId': message.clientId,
        'coachName': coach?.name ?? 'Coach',
        'coachAvatarUrl': coach?.avatarUrl,
        'clientName': client?.name ?? 'Client',
        'clientAvatarUrl': client?.avatarUrl,
        'lastMessage': {
          'content': message.content,
          'sentAt': FieldValue.serverTimestamp(),
          'senderId': message.senderId,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - conversation update is not critical
    }
  }

  String _getConversationId(String coachId, String clientId) {
    final ids = [coachId, clientId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Future<List<Message>> getMessages({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Get messages where coachId and clientId match the two users
      final snapshot = await _firestore
          .collection('messages')
          .where('coachId', isEqualTo: userId1)
          .where('clientId', isEqualTo: userId2)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();
      
      // Also get reverse direction
      final snapshot2 = await _firestore
          .collection('messages')
          .where('coachId', isEqualTo: userId2)
          .where('clientId', isEqualTo: userId1)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();

      final allMessages = <Message>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...data,
          'sentAt': (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'readAt': (data['readAt'] as Timestamp?)?.toDate(),
        }));
      }
      
      for (final doc in snapshot2.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...data,
          'sentAt': (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'readAt': (data['readAt'] as Timestamp?)?.toDate(),
        }));
      }
      
      allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return allMessages;
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  @override
  Future<List<Conversation>> getConversations(String userId) async {
    try {
      // Get conversations where user is either coach or client
      final coachSnapshot = await _firestore
          .collection('conversations')
          .where('coachId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      
      final clientSnapshot = await _firestore
          .collection('conversations')
          .where('clientId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final conversations = <Conversation>[];

      // Process coach conversations
      for (final doc in coachSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;

        conversations.add(Conversation.fromJson({
          'id': doc.id,
          ...data,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'lastMessage': lastMessageData != null
              ? {
                  'content': lastMessageData['content'],
                  'sentAt': (lastMessageData['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'senderId': lastMessageData['senderId'],
                  'id': '',
                  'receiverId': '',
                  'type': 'text',
                }
              : null,
        }));
      }

      // Process client conversations
      for (final doc in clientSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;

        conversations.add(Conversation.fromJson({
          'id': doc.id,
          ...data,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'lastMessage': lastMessageData != null
              ? {
                  'content': lastMessageData['content'],
                  'sentAt': (lastMessageData['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'senderId': lastMessageData['senderId'],
                  'id': '',
                  'receiverId': '',
                  'type': 'text',
                }
              : null,
        }));
      }

      // Remove duplicates and sort by updatedAt
      final uniqueConversations = <String, Conversation>{};
      for (final conv in conversations) {
        uniqueConversations[conv.id] = conv;
      }
      
      final sortedConversations = uniqueConversations.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return sortedConversations;
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('coachId', arrayContains: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  @override
  Stream<List<Message>> watchMessages({
    required String userId1,
    required String userId2,
  }) {
    // Combine both query streams
    final stream1 = _firestore
        .collection('messages')
        .where('coachId', isEqualTo: userId1)
        .where('clientId', isEqualTo: userId2)
        .orderBy('sentAt', descending: false)
        .snapshots();
    
    final stream2 = _firestore
        .collection('messages')
        .where('coachId', isEqualTo: userId2)
        .where('clientId', isEqualTo: userId1)
        .orderBy('sentAt', descending: false)
        .snapshots();

    return Rx.combineLatest2(stream1, stream2, (QuerySnapshot a, QuerySnapshot b) {
      return [a, b];
    }).map((snapshots) {
      final allMessages = <Message>[];
      
      for (final doc in (snapshots[0] as QuerySnapshot).docs) {
        final data = doc.data() as Map<String, dynamic>;
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...data,
          'sentAt': (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'readAt': (data['readAt'] as Timestamp?)?.toDate(),
        }));
      }
      
      for (final doc in (snapshots[1] as QuerySnapshot).docs) {
        final data = doc.data() as Map<String, dynamic>;
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...data,
          'sentAt': (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'readAt': (data['readAt'] as Timestamp?)?.toDate(),
        }));
      }
      
      allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return allMessages;
    });
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    // Combine streams for both coach and client conversations
    final coachStream = _firestore
        .collection('conversations')
        .where('coachId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
    
    final clientStream = _firestore
        .collection('conversations')
        .where('clientId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return Rx.combineLatest2(coachStream, clientStream, (QuerySnapshot a, QuerySnapshot b) {
      return [a, b];
    }).map((snapshots) {
      final conversations = <Conversation>[];
      
      // Process coach conversations
      for (final doc in (snapshots[0] as QuerySnapshot).docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;

        conversations.add(Conversation.fromJson({
          'id': doc.id,
          ...data,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'lastMessage': lastMessageData != null
              ? {
                  'content': lastMessageData['content'],
                  'sentAt': (lastMessageData['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'senderId': lastMessageData['senderId'],
                  'id': '',
                  'receiverId': '',
                  'type': 'text',
                }
              : null,
        }));
      }
      
      // Process client conversations
      for (final doc in (snapshots[1] as QuerySnapshot).docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;

        conversations.add(Conversation.fromJson({
          'id': doc.id,
          ...data,
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'lastMessage': lastMessageData != null
              ? {
                  'content': lastMessageData['content'],
                  'sentAt': (lastMessageData['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  'senderId': lastMessageData['senderId'],
                  'id': '',
                  'receiverId': '',
                  'type': 'text',
                }
              : null,
        }));
      }
      
      // Remove duplicates and sort
      final uniqueConversations = <String, Conversation>{};
      for (final conv in conversations) {
        uniqueConversations[conv.id] = conv;
      }
      
      final sortedConversations = uniqueConversations.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return sortedConversations;
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    required String conversationId,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('messages/$conversationId/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}

