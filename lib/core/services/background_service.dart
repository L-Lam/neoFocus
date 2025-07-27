import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static const String _timerKey = 'focus_timer_remaining';
  static const String _sessionTypeKey = 'focus_session_type';
  static const String _durationKey = 'focus_session_duration';
  static const String _isRunningKey = 'focus_session_running';

  static Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'focus_hero_timer',
        initialNotificationTitle: 'Focus Hero',
        initialNotificationContent: 'Timer is running',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize notifications for background service
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create notification channel
    const androidChannel = AndroidNotificationChannel(
      'focus_hero_timer',
      'Focus Timer',
      description: 'Shows the current focus session progress',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    Timer? timer;

    service.on('startTimer').listen((event) async {
      final duration = event?['duration'] as int? ?? 25;
      final type = event?['type'] as String? ?? 'focus';
      final totalSeconds = duration * 60;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_timerKey, totalSeconds);
      await prefs.setString(_sessionTypeKey, type);
      await prefs.setInt(_durationKey, duration);
      await prefs.setBool(_isRunningKey, true);

      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        final prefs = await SharedPreferences.getInstance();
        final remaining = prefs.getInt(_timerKey) ?? 0;
        final isRunning = prefs.getBool(_isRunningKey) ?? false;

        if (!isRunning || remaining <= 0) {
          timer.cancel();
          if (remaining <= 0) {
            // Session complete
            service.invoke('sessionComplete', {
              'type': prefs.getString(_sessionTypeKey) ?? 'focus',
            });
          }
          return;
        }

        final newRemaining = remaining - 1;
        await prefs.setInt(_timerKey, newRemaining);

        // Update notification
        _updateNotification(
          flutterLocalNotificationsPlugin,
          newRemaining,
          prefs.getString(_sessionTypeKey) ?? 'focus',
        );

        // Send update to app
        service.invoke('timerUpdate', {'remaining': newRemaining});
      });
    });

    service.on('pauseTimer').listen((event) async {
      timer?.cancel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isRunningKey, false);
    });

    service.on('resumeTimer').listen((event) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isRunningKey, true);

      // Restart timer from current remaining time
      service.invoke('startTimer', {
        'duration': 0, // Will use remaining time
        'type': prefs.getString(_sessionTypeKey) ?? 'focus',
      });
    });

    service.on('stopTimer').listen((event) async {
      timer?.cancel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await service.stopSelf();
    });
  }

  static void _updateNotification(
    FlutterLocalNotificationsPlugin notifications,
    int remainingSeconds,
    String sessionType,
  ) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    String title;
    String emoji;

    switch (sessionType) {
      case 'focus':
        title = 'Focus Session';
        emoji = '🎯';
        break;
      case 'shortBreak':
        title = 'Short Break';
        emoji = '☕';
        break;
      case 'longBreak':
        title = 'Long Break';
        emoji = '🌟';
        break;
      default:
        title = 'Session';
        emoji = '⏱️';
    }

    notifications.show(
      888,
      '$emoji $title - $timeString',
      'Tap to open Focus Hero',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_hero_timer',
          'Focus Timer',
          channelDescription: 'Shows the current focus session progress',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
          enableVibration: false,
          playSound: false,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4A90E2),
          actions: [
            const AndroidNotificationAction(
              'open_app',
              'Open App',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  static Future<void> startBackgroundTimer({
    required int duration,
    required String sessionType,
  }) async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }

    _service.invoke('startTimer', {'duration': duration, 'type': sessionType});
  }

  static Future<void> pauseBackgroundTimer() async {
    _service.invoke('pauseTimer');
  }

  static Future<void> resumeBackgroundTimer() async {
    _service.invoke('resumeTimer');
  }

  static Future<void> stopBackgroundTimer() async {
    _service.invoke('stopTimer');
  }

  static Future<int?> getRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_timerKey);
  }

  static Future<bool> isTimerRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRunningKey) ?? false;
  }
}
