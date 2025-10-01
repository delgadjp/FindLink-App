import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _caseStatusChannel =
      AndroidNotificationChannel(
    'case_status_updates',
    'Case Status Updates',
    description: 'Notifications when your case status changes.',
    importance: Importance.high,
  );

  Future<void> initialize({bool requestPermission = true}) async {
    if (_initialized) return;

    if (requestPermission && !kIsWeb) {
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );
        debugPrint('Notification permission status: '
            '${settings.authorizationStatus}');
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
      }
    }

    await _configureLocalNotifications();

    if (requestPermission) {
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    }

    await _setupFcmTokenPersistence();

    _initialized = true;
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    final iOSSettings = DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_caseStatusChannel);
  }

  Future<void> _setupFcmTokenPersistence() async {
    try {
      final token = await _messaging.getToken();
      await _saveFcmToken(token);

      _messaging.onTokenRefresh.listen((refreshedToken) {
        _saveFcmToken(refreshedToken);
      });
    } catch (e) {
      debugPrint('Error retrieving FCM token: $e');
    }
  }

  Future<void> _saveFcmToken(String? token) async {
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  Future<void> refreshFcmToken() async {
    try {
      final token = await _messaging.getToken();
      await _saveFcmToken(token);
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _showNotificationFromRemoteMessage(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    // Reserved for future deep-link navigation if needed.
  }

  Future<void> _showNotificationFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Case Update';
    final body = notification?.body ??
        message.data['body'] ??
        'Your case status has been updated.';

    final id = message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: message.data.isEmpty ? null : message.data,
    );
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _showNotificationFromRemoteMessage(message);
  }

  Future<void> showCaseStatusNotification({
    required String caseId,
    required String caseNumber,
    required String status,
    String? caseName,
  }) async {
    final title = 'Case status updated';
    final body = (caseName != null && caseName.trim().isNotEmpty)
        ? 'Case $caseNumber for $caseName is now $status.'
        : 'Case $caseNumber is now $status.';

    await showLocalNotification(
      id: caseId.hashCode & 0x7fffffff,
      title: title,
      body: body,
      payload: {
        'caseId': caseId,
        'caseNumber': caseNumber,
        'status': status,
      },
    );
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _caseStatusChannel.id,
        _caseStatusChannel.name,
        channelDescription: _caseStatusChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService().initialize(requestPermission: false);
  await NotificationService().handleBackgroundMessage(message);
}
