import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_app/services/notification_router.dart';
import 'package:flutter/widgets.dart';

class PushNotificationService {
  static bool _initialized = false;
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _local.initialize(settings);

      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
            ),
          );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(NotificationRouter.handle);

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationRouter.handle(initialMessage);
        });
      }

      _saveTokenSafe();
      FirebaseMessaging.instance.onTokenRefresh.listen(
        _saveTokenToFirestoreSafe,
      );
    } catch (e, st) {
      debugPrint('PushNotificationService init failed: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _saveTokenSafe() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestoreSafe(token);
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }
  }

  static Future<void> _saveTokenToFirestoreSafe(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "fcmToken": token,
        "fcmUpdatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Saving FCM token failed: $e');
    }
  }

  static void _showForegroundNotification(RemoteMessage message) {
    try {
      final n = message.notification;
      if (n == null) return;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      _local.show(n.hashCode, n.title, n.body, details);
    } catch (e) {
      debugPrint('Foreground notification failed: $e');
    }
  }
}
