import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_category.dart';

class FocusDetectionService extends ChangeNotifier {
  static const platform = MethodChannel('focus_hero/activity');

  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  String _currentApp = '';
  DateTime? _appStartTime;
  final Map<String, int> _appUsageTime = {}; // app name -> seconds
  final List<String> _recentApps = [];

  bool get isMonitoring => _isMonitoring;
  String get currentApp => _currentApp;
  Map<String, int> get appUsageTime => Map.unmodifiable(_appUsageTime);
  List<String> get recentApps => List.unmodifiable(_recentApps);

  // Start monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _appStartTime = DateTime.now();

    // For web/desktop, we'll use a simulated approach
    // For mobile, this would use platform channels
    _monitoringTimer = Timer.periodic(
      const Duration(
        seconds: 5,
      ), // Check every 5 seconds for battery efficiency
      (_) => _checkCurrentApp(),
    );

    notifyListeners();
  }

  // Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    _updateAppUsageTime();
    notifyListeners();
  }

  // Check current app (platform-specific implementation needed)
  Future<void> _checkCurrentApp() async {
    try {
      // This is a placeholder - actual implementation would use platform channels
      // For now, we'll simulate app detection
      final detectedApp = await _detectCurrentApp();

      if (detectedApp != _currentApp) {
        _updateAppUsageTime();
        _currentApp = detectedApp;
        _appStartTime = DateTime.now();

        if (detectedApp.isNotEmpty && !_recentApps.contains(detectedApp)) {
          _recentApps.add(detectedApp);
          if (_recentApps.length > 10) {
            _recentApps.removeAt(0);
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error detecting current app: $e');
    }
  }

  // Update app usage time
  void _updateAppUsageTime() {
    if (_currentApp.isNotEmpty && _appStartTime != null) {
      final duration = DateTime.now().difference(_appStartTime!).inSeconds;
      _appUsageTime[_currentApp] = (_appUsageTime[_currentApp] ?? 0) + duration;
    }
  }

  // Placeholder for actual app detection
  Future<String> _detectCurrentApp() async {
    // In a real implementation, this would use platform channels to get the current app
    // For now, return empty string (Focus Hero is active)
    return '';
  }

  // Get distracting apps used during session
  List<String> getDistractingApps() {
    return _recentApps.where((app) {
      final category = AppCategories.categorizeApp(app);
      return !category.isProductive;
    }).toList();
  }

  // Calculate focus score based on app usage
  double calculateFocusScore() {
    if (_appUsageTime.isEmpty) return 1.0;

    double totalImpact = 0;
    int totalTime = 0;

    _appUsageTime.forEach((app, time) {
      final category = AppCategories.categorizeApp(app);
      totalImpact += category.focusImpact * time;
      totalTime += time;
    });

    if (totalTime == 0) return 1.0;

    // Normalize to 0.0 - 1.0 range
    final score = (totalImpact / totalTime + 1.0) / 2.0;
    return score.clamp(0.0, 1.0);
  }

  // Clear session data
  void clearSession() {
    _currentApp = '';
    _appStartTime = null;
    _appUsageTime.clear();
    _recentApps.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
