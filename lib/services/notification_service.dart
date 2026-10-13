import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_language.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notification received: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'technician_activity_alerts_v2';
  static bool _initialized = false;

  static AndroidNotificationChannel get _localizedChannel {
    final languageCode = AppLanguage.instance.locale.languageCode;
    return AndroidNotificationChannel(
      _channelId,
      AppText.translateForLocale('Technician activity', languageCode),
      description: AppText.translateForLocale(
        'Updates about technician jobs and schedule changes.',
        languageCode,
      ),
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await _openNotificationPayload(response.payload);
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_localizedChannel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _openNotificationData(message.data);
    });
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _openNotificationData(initialMessage.data);
    }
    _initialized = true;
  }

  static Future<void> registerTechnician(int technicianId) async {
    if (kIsWeb) return;

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await ApiService.registerNotificationToken(
        technicianId: technicianId,
        token: token,
      );
    }

    _messaging.onTokenRefresh.listen((newToken) {
      ApiService.registerNotificationToken(
        technicianId: technicianId,
        token: newToken,
      );
    });
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title'] ?? 'Technician update';
    final body = notification?.body ??
        message.data['message'] ??
        message.data['body'] ??
        'You have a new update.';

    if (title == null || body == null) return;
    final languageCode = AppLanguage.instance.locale.languageCode;
    final localizedTitle = AppText.translateForLocale(title, languageCode);
    final localizedBody = AppText.translateForLocale(body, languageCode);
    final channel = _localizedChannel;
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.show(
      message.hashCode,
      localizedTitle,
      localizedBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: localizedTitle,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _openNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        await _openNotificationData(decoded);
      }
    } on FormatException catch (error) {
      debugPrint('Unable to read technician notification payload: $error');
    }
  }

  static Future<void> _openNotificationData(
    Map<String, dynamic> data,
  ) async {
    if (data['type'] != 'job_card_shared') return;

    final url = data['job_card_url']?.toString();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      debugPrint('Job-card notification did not contain a valid PDF link.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      debugPrint('Unable to open the shared job card from the notification.');
    }
  }
}
