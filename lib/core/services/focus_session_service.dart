import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../core/services/notification_service.dart';
import '../models/focus_session_model.dart';
import '../models/user_model.dart';
import 'background_service.dart';
import 'firebase_service.dart';
import 'user_service.dart';

class FocusSessionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final UserService _userService;

  FocusSession? _currentSession;
  Timer? _timer;
  int _pomodoroCount =
      0; // Tracks which pomodoro we're on (0-3, resets to 0 after long break)

  FocusSession? get currentSession => _currentSession;
  bool get isTimerRunning => _timer != null && _timer!.isActive;

  FocusSessionService(this._userService);

  // Get user preferences
  UserPreferences? get _userPreferences =>
      _userService.currentUser?.preferences;

  // Start a new focus session
  Future<void> startFocusSession() async {
    final user = _userService.currentUser;
    if (user == null) return;

    final duration = _userPreferences?.focusDuration ?? 25;

    _currentSession = FocusSession(
      id: '',
      userId: user.uid,
      type: SessionType.focus,
      status: SessionStatus.inProgress,
      duration: duration,
      remainingSeconds: duration * 60,
      startedAt: DateTime.now(),
      pomodoroCount: _pomodoroCount + 1,
    );

    // Save to Firestore
    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .add(_currentSession!.toMap());

    _currentSession = _currentSession!.copyWith(id: docRef.id);
    notifyListeners();
    await BackgroundService.startBackgroundTimer(
      duration: duration,
      sessionType: 'focus',
    );
    _startTimer();
    _listenToBackgroundUpdates();
  }

  void _listenToBackgroundUpdates() {
    FlutterBackgroundService().on('timerUpdate').listen((event) {
      final remaining = event?['remaining'] as int?;
      if (remaining != null && _currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          remainingSeconds: remaining,
        );
        notifyListeners();
      }
    });

    FlutterBackgroundService().on('sessionComplete').listen((event) {
      _completeSession();
    });
  }

  // Start a break session
  Future<void> startBreakSession({required bool isLongBreak}) async {
    final user = _userService.currentUser;
    if (user == null) return;

    final duration =
        isLongBreak
            ? (_userPreferences?.longBreakDuration ?? 15)
            : (_userPreferences?.breakDuration ?? 5);

    _currentSession = FocusSession(
      id: '',
      userId: user.uid,
      type: isLongBreak ? SessionType.longBreak : SessionType.shortBreak,
      status: SessionStatus.inProgress,
      duration: duration,
      remainingSeconds: duration * 60,
      startedAt: DateTime.now(),
      pomodoroCount: _pomodoroCount,
    );

    // Save to Firestore
    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .add(_currentSession!.toMap());

    _currentSession = _currentSession!.copyWith(id: docRef.id);
    notifyListeners();

    _startTimer();
  }

  // Pause the current session
  Future<void> pauseSession() async {
    if (_currentSession == null ||
        _currentSession!.status != SessionStatus.inProgress) {
      return;
    }

    _timer?.cancel();
    await BackgroundService.pauseBackgroundTimer();

    _currentSession = _currentSession!.copyWith(
      status: SessionStatus.paused,
      pausedAt: DateTime.now(),
    );

    await _updateSession();
    notifyListeners();
  }

  // Resume the current session
  Future<void> resumeSession() async {
    if (_currentSession == null ||
        _currentSession!.status != SessionStatus.paused) {
      return;
    }

    await BackgroundService.resumeBackgroundTimer();

    _currentSession = _currentSession!.copyWith(
      status: SessionStatus.inProgress,
      pausedAt: null,
    );

    await _updateSession();
    notifyListeners();

    _startTimer();
  }

  // Stop/Cancel the current session
  Future<void> stopSession() async {
    _timer?.cancel();
    await BackgroundService.stopBackgroundTimer();

    if (_currentSession != null) {
      // Record failed session for ELO calculation
      final sessionDuration = _currentSession!.duration;
      final timeElapsed =
          _currentSession!.duration * 60 - _currentSession!.remainingSeconds;
      final focusQuality = (timeElapsed / (_currentSession!.duration * 60))
          .clamp(0.0, 1.0);

      // For failed sessions, we don't add any focus time
      // Rating will naturally decrease if user doesn't focus enough weekly

      // Delete the incomplete session
      await _firestore
          .collection('users')
          .doc(_currentSession!.userId)
          .collection('sessions')
          .doc(_currentSession!.id)
          .delete();
    }

    _currentSession = null;
    notifyListeners();
  }

  // Update the _completeSession method
  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    _timer?.cancel();

    final completedType = _currentSession!.type;
    final wasXpEarned = completedType == SessionType.focus ? 20 : 0;

    _currentSession = _currentSession!.copyWith(
      status: SessionStatus.completed,
      completedAt: DateTime.now(),
    );

    await _updateSession();

    // If it was a focus session, update user stats
    if (_currentSession!.type == SessionType.focus) {
      await _updateUserStats();
      _pomodoroCount++;

      // After 4 pomodoros, reset the count
      if (_pomodoroCount >= 4) {
        _pomodoroCount = 0;
      }
    }

    // Determine next session type
    final nextSessionType = getNextSessionType();

    // Show notification
    final userPrefs = _userService.currentUser?.preferences;
    if (userPrefs?.notificationsEnabled ?? true) {
      await NotificationService.showSessionCompleteNotification(
        completedType: completedType,
        nextType: nextSessionType,
        xpEarned: wasXpEarned,
      );
    }

    // Clear current session temporarily
    _currentSession = null;
    notifyListeners();

    // Auto-start next session after a short delay (3 seconds)
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentSession == null) {
        // Only start if user hasn't manually started
        if (nextSessionType == SessionType.focus) {
          startFocusSession();
        } else {
          startBreakSession(
            isLongBreak: nextSessionType == SessionType.longBreak,
          );
        }
      }
    });
  }

  // Add method to handle notification settings
  void updateNotificationSettings() {
    final prefs = _userService.currentUser?.preferences;
    if (prefs != null) {
      NotificationService.updateSettings(
        soundEnabled: prefs.soundEnabled,
        vibrationEnabled: prefs.vibrationEnabled,
      );
    }
  }

  // Update session in Firestore
  Future<void> _updateSession() async {
    if (_currentSession == null || _currentSession!.id.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(_currentSession!.userId)
        .collection('sessions')
        .doc(_currentSession!.id)
        .update(_currentSession!.toMap());
  }

  // Update user statistics after completing a focus session
  Future<void> _updateUserStats() async {
    final user = _userService.currentUser;
    if (user == null || _currentSession == null) return;

    // Calculate minutes focused
    final minutesFocused = _currentSession!.duration;

    // Add to weekly focus time (this is what determines rating)
    await _userService.addWeeklyFocusTime(minutesFocused);

    // Update total focus minutes for other stats
    await _userService.updateStats(
      totalFocusMinutes: user.totalFocusMinutes + minutesFocused,
    );

    // Check for streak
    await _updateStreak();
  }

  // Update streak
  Future<void> _updateStreak() async {
    final user = _userService.currentUser;
    if (user == null) return;

    // Check if user has completed a session today
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final todaysSessions =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .where('completedAt', isGreaterThanOrEqualTo: startOfToday)
            .where('type', isEqualTo: 'focus')
            .where('status', isEqualTo: 'completed')
            .get();

    if (todaysSessions.docs.isNotEmpty) {
      // Update streak
      int newStreak = user.currentStreak;

      // Check if yesterday had a session
      final yesterday = today.subtract(const Duration(days: 1));
      final startOfYesterday = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      final endOfYesterday = startOfToday;

      final yesterdaysSessions =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('sessions')
              .where('completedAt', isGreaterThanOrEqualTo: startOfYesterday)
              .where('completedAt', isLessThan: endOfYesterday)
              .where('type', isEqualTo: 'focus')
              .where('status', isEqualTo: 'completed')
              .get();

      if (yesterdaysSessions.docs.isNotEmpty) {
        newStreak = user.currentStreak + 1;
      } else {
        newStreak = 1; // Reset streak to 1
      }

      await _userService.updateStats(
        currentStreak: newStreak,
        longestStreak: newStreak > user.longestStreak ? newStreak : null,
      );
    }
  }

  // Timer management
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_currentSession == null ||
          _currentSession!.status != SessionStatus.inProgress) {
        _timer?.cancel();
        return;
      }

      final newRemainingSeconds = _currentSession!.remainingSeconds - 1;

      if (newRemainingSeconds <= 0) {
        await _completeSession();
      } else {
        _currentSession = _currentSession!.copyWith(
          remainingSeconds: newRemainingSeconds,
        );
        notifyListeners();

        // Update Firestore every 10 seconds to save progress
        if (newRemainingSeconds % 10 == 0) {
          await _updateSession();
        }
      }
    });
  }

  // Get session history
  Stream<List<FocusSession>> getSessionHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FocusSession.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Get today's completed sessions count
  Future<int> getTodaySessionCount(String userId) async {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('sessions')
            .where('completedAt', isGreaterThanOrEqualTo: startOfToday)
            .where('type', isEqualTo: 'focus')
            .where('status', isEqualTo: 'completed')
            .get();

    return snapshot.docs.length;
  }

  // Determine next session type
  SessionType getNextSessionType() {
    if (_currentSession?.type == SessionType.focus) {
      // After focus, take a break
      return _pomodoroCount >= 4
          ? SessionType.longBreak
          : SessionType.shortBreak;
    } else {
      // After break, focus
      return SessionType.focus;
    }
  }

  // Check if it's time for a long break
  bool shouldTakeLongBreak() {
    return _pomodoroCount >= 4;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
