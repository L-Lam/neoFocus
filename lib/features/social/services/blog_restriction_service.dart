import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlogRestrictionService extends ChangeNotifier {
  static const int dailyLimitMinutes = 30; // 30 minutes daily limit
  static const String _lastAccessKey = 'blog_last_access';
  static const String _dailyUsageKey = 'blog_daily_usage';
  static const String _lastResetKey = 'blog_last_reset';

  DateTime? _sessionStartTime;
  int _todayUsageSeconds = 0;
  bool _isAccessAllowed = true;

  int get remainingMinutes =>
      ((dailyLimitMinutes * 60 - _todayUsageSeconds) / 60).ceil();

  bool get isAccessAllowed => _isAccessAllowed;

  BlogRestrictionService() {
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset daily usage
    final lastResetStr = prefs.getString(_lastResetKey);
    final today = DateTime.now();

    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      if (today.day != lastReset.day ||
          today.month != lastReset.month ||
          today.year != lastReset.year) {
        // New day, reset usage
        await _resetDailyUsage();
        return;
      }
    }

    _todayUsageSeconds = prefs.getInt(_dailyUsageKey) ?? 0;
    _checkAccessStatus();
    notifyListeners();
  }

  Future<void> _resetDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    _todayUsageSeconds = 0;
    await prefs.setInt(_dailyUsageKey, 0);
    await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
    _checkAccessStatus();
    notifyListeners();
  }

  void startSession() {
    if (!_isAccessAllowed) return;
    _sessionStartTime = DateTime.now();
  }

  Future<void> endSession() async {
    if (_sessionStartTime == null) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    _todayUsageSeconds += sessionDuration.inSeconds;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyUsageKey, _todayUsageSeconds);

    _sessionStartTime = null;
    _checkAccessStatus();
    notifyListeners();
  }

  void _checkAccessStatus() {
    _isAccessAllowed = _todayUsageSeconds < (dailyLimitMinutes * 60);
  }

  String getTimeRemaining() {
    final remainingSeconds = (dailyLimitMinutes * 60) - _todayUsageSeconds;
    if (remainingSeconds <= 0) return "0:00";

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}
