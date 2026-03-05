import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> init() async {
    print('PushNotificationService initializing...');
    // Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get the token
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        print('FCM Token Refreshed: $newToken');
        _saveToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.notification?.title}');
        print('Message Data: ${message.data}');
        if (message.notification != null) {
          NotificationService.instance.showNotification(
            id: DateTime.now().millisecond,
            title: message.notification!.title ?? 'New Message',
            body: message.notification!.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });

      // Handle background notification taps (app not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification opened app: ${message.data}');
        NotificationService.instance.handleExternalPayload(message.data);
      });

      // Handle notification taps (app terminated)
      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('Initial message: ${message.data}');
          NotificationService.instance.handleExternalPayload(message.data);
        }
      });

      // Also listen for auth state changes to sync token when user logs in
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          print('Auth state changed ($event), re-syncing FCM token...');
          _fcm.getToken().then((token) {
            if (token != null) _saveToken(token);
          });
        }
      });
    } else {
      print('User denied or has not yet accepted notification permissions');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('Cannot save FCM token: User not logged in');
      return;
    }

    try {
      print('Syncing FCM token to Supabase for user: $userId');
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      print('✅ FCM Token successfully saved to profile');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }
}
