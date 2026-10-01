import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service responsible for dispatching mission-critical system notifications.
/// Uses Time-Sensitive notifications on iOS and Maximum High-Priority Alarm channels on Android.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'alarmer_critical_price_alerts';
  static const String channelName = 'Price & Market Alerts';
  static const String channelDescription =
      'High-priority urgent alerts when crypto or market price targets and percentage changes occur.';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS configuration using Time-Sensitive Interruption Level
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Deep-link handling
      },
    );

    // Create Max-Importance Android notification channel with sound & vibration
    final vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);
    final androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      showBadge: true,
      enableLights: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(androidChannel);

    // Explicitly request notification & alarm permissions on Android 13+ (API 33+)
    await requestPermissions();
  }

  /// Request runtime permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await androidPlugin?.requestNotificationsPermission() ?? true;
      await androidPlugin?.requestExactAlarmsPermission();

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? true;

      return androidGranted && iosGranted;
    } catch (_) {
      return false;
    }
  }

  /// Dispatches an immediate high-priority alert notification with sound and vibration
  Future<void> showCriticalAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // 1. In-App Audio & Haptic Feedback
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    // 2. System Level Notification Banner
    final vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Alarmer Price Alert',
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Alarmer',
      ),
    );

    // Time-Sensitive Interruption Level allows breaking through Focus Modes on iOS
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
