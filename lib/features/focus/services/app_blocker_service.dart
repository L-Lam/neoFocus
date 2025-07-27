import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppBlockerService extends ChangeNotifier {
  static const platform = MethodChannel('com.focushero/app_blocker');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _monitoringTimer;
  List<String> _blockedApps = [];
  bool _isBlocking = false;

  // Installed apps cache
  List<AppInfo> _installedApps = [];

  bool get isBlocking => _isBlocking;
  List<AppInfo> get installedApps => _installedApps;

  AppBlockerService() {
    _initializeNotifications();
    _loadInstalledApps();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> _loadInstalledApps() async {
    if (Platform.isAndroid) {
      try {
        // Get all installed apps
        final apps = await InstalledApps.getInstalledApps(
          true, // Include app icons
          true, // Include system apps (we'll filter them manually)
        );

        // Filter out system apps and our own app
        _installedApps =
            apps.where((app) => !_isSystemApp(app.packageName)).toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        notifyListeners();
      } catch (e) {
        print('Error loading installed apps: $e');
      }
    }
  }

  bool _isSystemApp(String packageName) {
    // Filter out system apps and our own app
    final systemPackages = [
      'com.android',
      'com.google.android',
      'com.samsung',
      'com.sec',
      'com.example.smartlock', // Our app
      'com.focushero', // Our app alternate package name
    ];

    return systemPackages.any((prefix) => packageName.startsWith(prefix));
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Request usage stats permission
      final usageStatus = await Permission.appTrackingTransparency.request();

      // On Android, we need special permission for usage stats
      if (!await _hasUsageStatsPermission()) {
        await _openUsageStatsSettings();
        return false;
      }

      // Request overlay permission for blocking
      if (!await Permission.systemAlertWindow.isGranted) {
        await Permission.systemAlertWindow.request();
      }

      // Request notification permission
      await Permission.notification.request();

      return true;
    } else if (Platform.isIOS) {
      // iOS requires Screen Time API access
      // This needs to be configured in Screen Time settings
      await _showiOSInstructions();
      return false;
    }

    return false;
  }

  Future<bool> _hasUsageStatsPermission() async {
    try {
      final result = await platform.invokeMethod('hasUsageStatsPermission');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<void> _openUsageStatsSettings() async {
    try {
      await platform.invokeMethod('openUsageStatsSettings');
    } catch (e) {
      print('Error opening usage stats settings: $e');
    }
  }

  Future<void> startBlocking(List<String> appPackageNames) async {
    if (!await requestPermissions()) {
      throw Exception('Required permissions not granted');
    }

    _blockedApps = appPackageNames;
    _isBlocking = true;
    notifyListeners();

    if (Platform.isAndroid) {
      // Start monitoring in foreground service
      await _startAndroidBlocking();
    } else if (Platform.isIOS) {
      // iOS implementation
      await _startiOSBlocking();
    }

    // Start monitoring timer
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkRunningApps(),
    );
  }

  Future<void> stopBlocking() async {
    _isBlocking = false;
    _blockedApps.clear();
    _monitoringTimer?.cancel();
    notifyListeners();

    if (Platform.isAndroid) {
      await _stopAndroidBlocking();
    }
  }

  Future<void> _startAndroidBlocking() async {
    try {
      await platform.invokeMethod('startBlocking', {
        'blockedApps': _blockedApps,
      });
    } catch (e) {
      print('Error starting Android blocking: $e');
    }
  }

  Future<void> _stopAndroidBlocking() async {
    try {
      await platform.invokeMethod('stopBlocking');
    } catch (e) {
      print('Error stopping Android blocking: $e');
    }
  }

  Future<void> _startiOSBlocking() async {
    // Show instructions for iOS Screen Time
    await _showiOSInstructions();
  }

  Future<void> _checkRunningApps() async {
    if (!_isBlocking || _blockedApps.isEmpty) return;

    if (Platform.isAndroid) {
      try {
        // Get current foreground app
        final currentApp = await _getCurrentForegroundApp();

        if (currentApp != null && _blockedApps.contains(currentApp)) {
          // App is blocked, show blocking screen
          await _showBlockingNotification(currentApp);
          await _minimizeBlockedApp();
        }
      } catch (e) {
        print('Error checking apps: $e');
      }
    }
  }

  Future<String?> _getCurrentForegroundApp() async {
    try {
      // Get app usage for the last minute
      final endTime = DateTime.now();
      final startTime = endTime.subtract(const Duration(minutes: 1));

      final appUsageList = await AppUsage().getAppUsage(startTime, endTime);

      if (appUsageList.isNotEmpty) {
        // Sort by end time to get most recent
        appUsageList.sort((a, b) {
          // Use endDate instead of lastUsed
          final aEndTime = a.endDate ?? DateTime(1970);
          final bEndTime = b.endDate ?? DateTime(1970);
          return bEndTime.compareTo(aEndTime);
        });

        final recentApp = appUsageList.first;

        // Check if app was used recently
        if (recentApp.endDate != null) {
          final timeSinceLastUse = DateTime.now().difference(
            recentApp.endDate!,
          );
          if (timeSinceLastUse.inSeconds < 5) {
            return recentApp.packageName;
          }
        }

        // Alternative: Check if any app has usage in the last few seconds
        for (final app in appUsageList) {
          if (app.usage.inSeconds > 0 && app.endDate != null) {
            final timeSinceEnd = DateTime.now().difference(app.endDate!);
            if (timeSinceEnd.inSeconds < 5) {
              return app.packageName;
            }
          }
        }
      }
    } catch (e) {
      print('Error getting foreground app: $e');
      // Try alternative method using native platform channel
      try {
        final result = await platform.invokeMethod('getCurrentForegroundApp');
        return result as String?;
      } catch (e) {
        print('Error getting foreground app from platform: $e');
      }
    }

    return null;
  }

  Future<void> _minimizeBlockedApp() async {
    try {
      // Return to home screen
      await platform.invokeMethod('minimizeApp');
    } catch (e) {
      print('Error minimizing app: $e');
    }
  }

  Future<void> _showBlockingNotification(String appPackage) async {
    // Find the app info
    AppInfo? appInfo;
    try {
      appInfo = _installedApps.firstWhere(
        (app) => app.packageName == appPackage,
      );
    } catch (e) {
      // App not found in list
    }

    const androidDetails = AndroidNotificationDetails(
      'app_blocker',
      'App Blocker',
      channelDescription: 'Notifications when blocked apps are opened',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'App Blocked',
      '${appInfo?.name ?? appPackage} is blocked during focus session',
      details,
    );
  }

  Future<void> _showiOSInstructions() async {
    // This would show a dialog with instructions for iOS users
    // to set up Screen Time restrictions
    print('iOS users need to use Screen Time to block apps');
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    stopBlocking();
    super.dispose();
  }
}
