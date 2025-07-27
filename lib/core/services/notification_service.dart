import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/focus_session_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static bool _isInitialized = false;
  static bool _soundEnabled = true;
  static bool _vibrationEnabled = true;

  static const String _channelId = 'focus_hero_notifications';
  static const String _channelName = 'Focus Hero';
  static const String _channelDescription =
      'Notifications for focus sessions and breaks';

  // Notification IDs
  static const int _sessionCompleteId = 1;
  static const int _breakRemindeId = 2;
  static const int _dailyReminderId = 3;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
  }

  static Future<void> _requestPermissions() async {
    await Permission.notification.request();

    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      print('Device supports vibration');
    }
  }

  static void updateSettings({bool? soundEnabled, bool? vibrationEnabled}) {
    if (soundEnabled != null) _soundEnabled = soundEnabled;
    if (vibrationEnabled != null) _vibrationEnabled = vibrationEnabled;
  }

  static Future<void> showSessionCompleteNotification({
    required SessionType completedType,
    required SessionType nextType,
    int? xpEarned,
  }) async {
    String title;
    String body;

    switch (completedType) {
      case SessionType.focus:
        title = '🎉 Focus Session Complete!';
        body =
            xpEarned != null
                ? 'Great job! You earned $xpEarned XP. Time for a ${_getSessionTypeName(nextType)}.'
                : 'Great job! Time for a ${_getSessionTypeName(nextType)}.';
        break;
      case SessionType.shortBreak:
        title = '☕ Break Complete!';
        body = 'Ready to focus again? Your next session is starting.';
        break;
      case SessionType.longBreak:
        title = '🌟 Long Break Complete!';
        body = 'Feeling refreshed? Let\'s start a new focus session!';
        break;
    }

    if (_soundEnabled) {
      await _playCompletionSound();
    }

    if (_vibrationEnabled) {
      await _vibrateCompletion();
    }

    await _notifications.show(
      _sessionCompleteId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: _vibrationEnabled,
          playSound: _soundEnabled,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4A90E2),
          actions: [
            const AndroidNotificationAction(
              'pause',
              'Pause',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'stop',
              'Stop',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> showBreakReminder() async {
    await _notifications.show(
      _breakRemindeId,
      '⏰ Time for a Break!',
      'You\'ve been focusing for a while. Take a short break to stay productive.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4A90E2),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> scheduleDailyReminder(String time) async {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    await _notifications.cancel(_dailyReminderId);

    await _notifications.periodicallyShow(
      _dailyReminderId,
      '🎯 Time to Focus!',
      'Start your daily focus session and stay productive.',
      RepeatInterval.daily,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4A90E2),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/sound.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  static Future<void> _vibrateCompletion() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId == 'pause') {
      print('Pause action tapped');
    } else if (response.actionId == 'stop') {
      print('Stop action tapped');
    }
  }

  static String _getSessionTypeName(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return 'focus session';
      case SessionType.shortBreak:
        return 'short break';
      case SessionType.longBreak:
        return 'long break';
    }
  }
}
