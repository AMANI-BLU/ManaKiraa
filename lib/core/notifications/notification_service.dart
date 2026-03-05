import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/chat/chat_detail_screen.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String _notificationsKeyPrefix = 'persisted_notifications';

  // Returns a user-specific storage key so notifications are private per account
  static String get _notificationsKey {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return _notificationsKeyPrefix;
    return '${_notificationsKeyPrefix}_$userId';
  }

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _navigateFromData(data);
        return;
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
    // Default fallback: open notifications screen
    navigatorKey.currentState?.pushNamed('/notifications');
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';

    if (type == 'new_listing') {
      navigatorKey.currentState?.pushNamed('/notifications');
      return;
    }

    // Chat / message — navigate directly to the chat thread
    final receiverId =
        data['receiverId']?.toString() ?? data['chat_id']?.toString();
    if (receiverId != null) {
      final chatArgs = {
        'name': data['senderName']?.toString() ?? 'Chat',
        'avatar': 'https://ui-avatars.com/api/?name=User&background=random',
        'isOnline': false,
        'propertyId': data['propertyId'],
        'receiverId': receiverId,
      };
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chatArgs)),
      );
      return;
    }

    // Final fallback
    navigatorKey.currentState?.pushNamed('/notifications');
  }

  void handleExternalPayload(Map<String, dynamic> data) {
    // If user is not logged in, redirect to login instead of app screens
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    if (!isLoggedIn) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
      );
      return;
    }
    _onNotificationTapped(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: jsonEncode(data),
      ),
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);

    // Extract extra data from the payload for navigation
    Map<String, dynamic>? extraData;
    if (payload != null) {
      try {
        extraData = Map<String, dynamic>.from(jsonDecode(payload));
      } catch (_) {}
    }

    // Persist this notification so it shows up in the notifications screen
    final notifType = extraData?['type']?.toString() == 'new_listing'
        ? 'new_listing'
        : 'chat'; // 'chat' so icons show correctly; navigation handles both 'chat' and 'message'
    await _persistNotification(title, body, notifType, extraData: extraData);
  }

  Future<void> _persistNotification(
    String title,
    String message,
    String type, {
    Map<String, dynamic>? extraData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingJson = prefs.getString(_notificationsKey);
    List<dynamic> notifications = existingJson != null
        ? jsonDecode(existingJson)
        : [];

    notifications.insert(0, {
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'timestamp': DateTime.now().toIso8601String(),
      if (extraData != null) ...extraData,
    });

    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }

    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  static Future<List<Map<String, dynamic>>> getPersistedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingJson = prefs.getString(_notificationsKey);
    if (existingJson == null) return [];
    final List<dynamic> decoded = jsonDecode(existingJson);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  Future<void> markAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingJson = prefs.getString(_notificationsKey);
    if (existingJson == null) return;

    List<dynamic> notifications = jsonDecode(existingJson);
    if (index >= 0 && index < notifications.length) {
      notifications[index]['isRead'] = true;
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }

  static Future<void> removeNotificationAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingJson = prefs.getString(_notificationsKey);
    if (existingJson == null) return;

    List<dynamic> notifications = jsonDecode(existingJson);
    if (index >= 0 && index < notifications.length) {
      notifications.removeAt(index);
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }
}
