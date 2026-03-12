import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifications/notification_service.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String? propertyId; // nullable — not all messages belong to a property
  final String content;
  final bool isRead;
  final bool isEdited;
  final String? replyToId;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? deletedAt;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.propertyId,
    required this.content,
    required this.isRead,
    this.isEdited = false,
    this.replyToId,
    this.attachmentUrl,
    this.attachmentType,
    this.deletedAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      propertyId: json['property_id'] as String?, // nullable
      content: json['content'] as String? ?? '', // empty string fallback
      isRead: json['is_read'] as bool? ?? false,
      isEdited: json['is_edited'] as bool? ?? false,
      replyToId: json['reply_to_id'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

class ChatService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Local registry to track read status for immediate UI feedback
  static final Map<String, DateTime> _localLastReadAt = {};

  // Profile cache to avoid redundant fetches
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  // Controller to notify UI about local state changes (e.g. marking as read)
  static final _localUpdates = StreamController<void>.broadcast();

  static StreamSubscription? _globalMessageSubscription;

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId]!;
    }

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = data as Map<String, dynamic>;
      _profileCache[userId] = profile;
      return profile;
    } catch (e) {
      print('Error fetching profile: $e');
      return {};
    }
  }

  static Stream<List<Message>> getMessagesStream(String otherUserId) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((json) => Message.fromJson(json))
              .where(
                (msg) =>
                    msg.deletedAt == null && // Don't show soft-deleted messages
                    ((msg.senderId == currentUserId &&
                            msg.receiverId == otherUserId) ||
                        (msg.senderId == otherUserId &&
                            msg.receiverId == currentUserId)),
              )
              .toList();
        });
  }

  static void startGlobalMessageListener() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _globalMessageSubscription?.cancel();
    _globalMessageSubscription = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(1) // Just the latest one
        .listen((data) async {
          if (data.isEmpty) return;

          final msgJson = data.first;
          final msg = Message.fromJson(msgJson);

          // Only show notification if it's unread and recent (not an old message being synced)
          final now = DateTime.now();
          if (!msg.isRead && now.difference(msg.createdAt).inSeconds < 30) {
            // Fetch sender name
            final senderData = await getProfile(msg.senderId);
            final senderName = senderData['full_name'] ?? 'New Message';

            NotificationService.instance.showNotification(
              id: msg.id.hashCode,
              title: senderName,
              body: msg.content.isEmpty && msg.attachmentUrl != null
                  ? '📷 Sent a photo'
                  : msg.content,
              payload: jsonEncode({
                'type': 'chat',
                'propertyId': msg.propertyId,
                'receiverId': msg.senderId,
                'senderName': senderName,
              }),
            );
          }
        });
  }

  static void stopGlobalMessageListener() {
    _globalMessageSubscription?.cancel();
    _globalMessageSubscription = null;
  }

  static Future<void> sendMessage({
    String? propertyId,
    required String receiverId,
    required String content,
    String? replyToId,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Not authenticated');

    await _client.from('messages').insert({
      if (propertyId != null && propertyId.isNotEmpty)
        'property_id': propertyId,
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    });

    // When I send a message, I've implicitly read their messages
    await markAsRead(receiverId);
  }

  static Future<void> editMessage(String messageId, String newContent) async {
    await _client
        .from('messages')
        .update({'content': newContent, 'is_edited': true})
        .eq('id', messageId);
  }

  static Future<void> deleteMessage(
    String messageId, {
    bool softDelete = true,
  }) async {
    if (softDelete) {
      await _client
          .from('messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId);
    } else {
      await _client.from('messages').delete().eq('id', messageId);
    }
  }

  static Future<void> deleteConversation(
    String propertyId,
    String otherUserId,
  ) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Delete all messages between these two users (both directions)
      // We do two separate deletes to avoid complex OR logic issues
      await _client
          .from('messages')
          .delete()
          .eq('sender_id', currentUserId)
          .eq('receiver_id', otherUserId);

      await _client
          .from('messages')
          .delete()
          .eq('sender_id', otherUserId)
          .eq('receiver_id', currentUserId);
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  // Presence logic
  static Future<void> updatePresence(bool isOnline) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final metadata = user.userMetadata ?? {};
      final fullName = metadata['full_name'] as String?;
      final avatarUrl = metadata['avatar_url'] as String?;

      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName ?? user.email?.split('@')[0] ?? 'User',
        'avatar_url': avatarUrl ?? '',
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating presence: $e');
    }
  }

  static Stream<Map<String, dynamic>> getUserPresence(String userId) {
    if (userId.isEmpty) {
      return Stream.value({'is_online': false, 'last_seen': null});
    }
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .map(
          (data) => data.isNotEmpty
              ? data.first
              : {'is_online': false, 'last_seen': null},
        );
  }

  static Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    final controller = StreamController<List<Map<String, dynamic>>>();
    StreamSubscription? dbSub;
    StreamSubscription? localSub;
    List<dynamic> lastRawData = [];

    Future<void> runProcess(List<dynamic> data) async {
      lastRawData = data;
      try {
        final messages = data
            .map((json) => Message.fromJson(json))
            .where(
              (msg) =>
                  msg.deletedAt == null &&
                  (msg.senderId == currentUserId ||
                      msg.receiverId == currentUserId),
            )
            .toList();

        final conversationsMap = <String, Message>{};
        final unreadCounts = <String, int>{};

        for (final msg in messages) {
          final otherUserId = msg.senderId == currentUserId
              ? msg.receiverId
              : msg.senderId;
          final key = otherUserId; // Group by user only

          if (conversationsMap[key] == null ||
              msg.createdAt.isAfter(conversationsMap[key]!.createdAt)) {
            conversationsMap[key] = msg;
          }

          // Unread Check: relies on database isRead status + local masking
          if (msg.receiverId == currentUserId && !msg.isRead) {
            final lastReadAt = _localLastReadAt[key];
            // If we've locally marked this conversation as read after this message was created, mask it
            if (lastReadAt == null || msg.createdAt.isAfter(lastReadAt)) {
              unreadCounts[key] = (unreadCounts[key] ?? 0) + 1;
            }
          }
        }

        final otherUserIds = conversationsMap.values
            .map(
              (msg) =>
                  msg.senderId == currentUserId ? msg.receiverId : msg.senderId,
            )
            .toSet()
            .toList();

        if (otherUserIds.isEmpty) {
          controller.add([]);
          return;
        }

        // Cache profiles
        final uncachedIds = otherUserIds
            .where((id) => !_profileCache.containsKey(id))
            .toList();
        if (uncachedIds.isNotEmpty) {
          try {
            final profilesData = await _client
                .from('profiles')
                .select()
                .filter('id', 'in', uncachedIds);
            for (var p in profilesData) {
              _profileCache[p['id'] as String] = p;
            }
          } catch (_) {}
        }

        final results = <Map<String, dynamic>>[];
        for (final entry in conversationsMap.entries) {
          final msg = entry.value;
          final otherUserId = msg.senderId == currentUserId
              ? msg.receiverId
              : msg.senderId;
          final profile = _profileCache[otherUserId];
          final email = profile?['email'] as String? ?? '';
          final isAdmin = email == 'admin@manakiraa.com';

          results.add({
            'propertyId': msg.propertyId,
            'receiverId': otherUserId,
            'name': isAdmin
                ? 'Mana Kira'
                : (profile?['full_name'] ??
                      'User ${otherUserId.substring(0, 4)}'),
            'avatar': profile?['avatar_url'] ?? '',
            'message': msg.content,
            'time': _formatChatTime(msg.createdAt),
            'unread': unreadCounts[entry.key] ?? 0,
            'isOnline': profile?['is_online'] ?? false,
            'lastMessageTime': msg.createdAt,
            'isAdmin': isAdmin,
          });
        }

        results.sort(
          (a, b) => (b['lastMessageTime'] as DateTime).compareTo(
            a['lastMessageTime'] as DateTime,
          ),
        );
        controller.add(results);
      } catch (e) {
        print('Error in getConversationsStream processing: $e');
      }
    }

    dbSub = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(runProcess);

    localSub = _localUpdates.stream.listen((_) => runProcess(lastRawData));

    controller.onCancel = () {
      dbSub?.cancel();
      localSub?.cancel();
    };

    return controller.stream;
  }

  static Stream<int> getTotalUnreadCountStream() {
    return getConversationsStream().map((conversations) {
      return conversations.fold<int>(
        0,
        (sum, chat) => sum + (chat['unread'] as int),
      );
    });
  }

  static String _formatChatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final minutes = date.minute < 10 ? '0${date.minute}' : '${date.minute}';
      return '$hour:$minutes $amPm';
    } else if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday > 0 && date.weekday <= 7 ? date.weekday - 1 : 0];
    } else {
      return '${date.day}/${date.month}';
    }
  }

  static Future<void> markAsRead(String otherUserId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Update in database first for persistence
      await _client.from('messages').update({'is_read': true}).match({
        'receiver_id': currentUserId,
        'sender_id': otherUserId,
        'is_read': false,
      });

      // Update local registry for instant UI feedback
      final key = otherUserId;
      _localLastReadAt[key] = DateTime.now();

      // Notify listeners to refresh UI
      _localUpdates.add(null);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  static Future<String?> uploadFile({
    required String path,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final extension = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$timestamp.$extension';

      await _client.storage
          .from('chat_attachments')
          .uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _client.storage
          .from('chat_attachments')
          .getPublicUrl(storagePath);
      return url;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  static Future<void> refreshConversations() async {
    // Supabase streams update automatically, but we can add a small delay
    // to simulate a refresh for the UI's RefreshIndicator.
    await Future.delayed(const Duration(milliseconds: 800));
  }
}
