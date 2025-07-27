import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/focus_session.dart';
import '../services/firebase_service.dart';
import 'focus_detection_service.dart';

class FocusStateManager extends ChangeNotifier {
  final FocusDetectionService _detectionService;

  FocusSession? _currentSession;
  Timer? _sessionTimer;
  Timer? _tickTimer;
  int _elapsedSeconds = 0;
  int _pausedDuration = 0;
  DateTime? _pauseStartTime;

  FocusSession? get currentSession => _currentSession;
  int get elapsedSeconds => _elapsedSeconds;
  int get remainingSeconds {
    if (_currentSession == null) return 0;
    final planned =
        _currentSession!.plannedDuration ?? _currentSession!.duration;
    return (planned * 60) - _elapsedSeconds;
  }

  bool get isActive =>
      _currentSession?.focusStatus == FocusSessionStatus.active;
  bool get isPaused =>
      _currentSession?.focusStatus == FocusSessionStatus.paused;

  FocusStateManager(this._detectionService);

  // Start a new focus session
  Future<void> startSession({
    required FocusSessionType type,
    required int duration,
  }) async {
    if (_currentSession != null) {
      await endSession(abandoned: true);
    }

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    final sessionId =
        FirebaseService.firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .doc()
            .id;

    _currentSession = FocusSession.forStateManager(
      id: sessionId,
      userId: user.uid,
      focusType: type,
      focusStatus: FocusSessionStatus.active,
      startTime: DateTime.now(),
      plannedDuration: duration,
      actualDuration: 0,
      distractingApps: [],
      distractionCount: 0,
      focusScore: 1.0,
    );

    _elapsedSeconds = 0;
    _pausedDuration = 0;

    // Start detection service
    await _detectionService.startMonitoring();

    // Start timers
    _startTimers();

    // Save initial session to Firestore
    await _saveSession();

    notifyListeners();
  }

  // Pause session
  Future<void> pauseSession() async {
    if (_currentSession == null || !isActive) return;

    _currentSession = _currentSession!.copyWith(
      focusStatus: FocusSessionStatus.paused,
    );

    _pauseStartTime = DateTime.now();
    _sessionTimer?.cancel();
    _tickTimer?.cancel();

    await _saveSession();
    notifyListeners();
  }

  // Resume session
  Future<void> resumeSession() async {
    if (_currentSession == null || !isPaused) return;

    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!).inSeconds;
    }

    _currentSession = _currentSession!.copyWith(
      focusStatus: FocusSessionStatus.active,
    );

    _startTimers();
    await _saveSession();
    notifyListeners();
  }

  // End session
  Future<void> endSession({bool abandoned = false}) async {
    if (_currentSession == null) return;

    _sessionTimer?.cancel();
    _tickTimer?.cancel();
    _detectionService.stopMonitoring();

    final actualDuration = _elapsedSeconds - _pausedDuration;
    final distractingApps = _detectionService.getDistractingApps();
    final focusScore = _detectionService.calculateFocusScore();

    _currentSession = _currentSession!.copyWith(
      focusStatus:
          abandoned
              ? FocusSessionStatus.abandoned
              : FocusSessionStatus.completed,
      endTime: DateTime.now(),
      actualDuration: actualDuration,
      distractingApps: distractingApps,
      distractionCount: distractingApps.length,
      focusScore: focusScore,
    );

    await _saveSession();
    await _updateUserStats();

    _detectionService.clearSession();
    _currentSession = null;
    _elapsedSeconds = 0;
    _pausedDuration = 0;

    notifyListeners();
  }

  // Start timers
  void _startTimers() {
    // Main session timer
    final remainingTime = Duration(seconds: remainingSeconds);
    _sessionTimer = Timer(remainingTime, () async {
      await endSession(abandoned: false);
    });

    // Tick timer for UI updates
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  // Save session to Firestore
  Future<void> _saveSession() async {
    if (_currentSession == null) return;

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    await FirebaseService.firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(_currentSession!.id)
        .set(_currentSession!.toMap());
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (_currentSession == null ||
        _currentSession!.focusStatus != FocusSessionStatus.completed)
      return;

    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    final userDoc = FirebaseService.firestore.collection('users').doc(user.uid);

    // Get current stats
    final userData = await userDoc.get();
    final data = userData.data() as Map<String, dynamic>?;

    if (data == null) return;

    final totalMinutes = data['totalFocusMinutes'] ?? 0;
    final actualDuration = _currentSession!.actualDuration ?? 0;
    final newTotalMinutes = totalMinutes + (actualDuration ~/ 60);

    // Check if this maintains streak
    final lastSessionDate =
        data['lastSessionDate'] != null
            ? (data['lastSessionDate'] as Timestamp).toDate()
            : null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int currentStreak = data['currentStreak'] ?? 0;
    int longestStreak = data['longestStreak'] ?? 0;

    if (lastSessionDate != null) {
      final lastDate = DateTime(
        lastSessionDate.year,
        lastSessionDate.month,
        lastSessionDate.day,
      );

      final daysDifference = todayDate.difference(lastDate).inDays;

      if (daysDifference == 0) {
        // Same day, don't change streak
      } else if (daysDifference == 1) {
        // Next day, increment streak
        currentStreak++;
      } else {
        // Streak broken, reset to 1
        currentStreak = 1;
      }
    } else {
      // First session ever
      currentStreak = 1;
    }

    longestStreak =
        currentStreak > longestStreak ? currentStreak : longestStreak;

    // Calculate new level (every 600 minutes = 10 hours = 1 level)
    final newLevel = (newTotalMinutes ~/ 600) + 1;

    // Update user stats
    await userDoc.update({
      'totalFocusMinutes': newTotalMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastSessionDate': FieldValue.serverTimestamp(),
      'level': newLevel,
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }
}
