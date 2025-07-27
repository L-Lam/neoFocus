import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../models/user_level.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class RewardService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Complete a focus session and update rewards
  static Future<void> completeSession({
    required String userId,
    required int duration,
    required String sessionType,
    int? distractionCount,
    double? focusScore,
  }) async {
    final userDoc = _firestore.collection('users').doc(userId);

    // Map string sessionType to enum
    final type =
        sessionType == 'focus'
            ? SessionType.focus
            : sessionType == 'longBreak'
            ? SessionType.longBreak
            : SessionType.shortBreak;

    // Create session record with the unified structure
    final session = FocusSession(
      id: '', // Will be assigned by Firestore
      userId: userId,
      type: type,
      status: SessionStatus.completed,
      startTime: DateTime.now().subtract(Duration(minutes: duration)),
      endTime: DateTime.now(),
      duration: duration,
      elapsedSeconds: duration * 60,
      blockedApps:
          [], // Empty for now, will be populated when app blocking is implemented
      pomodoroCount:
          0, // Will be tracked when pomodoro feature is fully implemented
      notes: null,
      // New fields for focus detection
      plannedDuration: duration,
      actualDuration: duration * 60,
      distractionCount: distractionCount,
      focusScore: focusScore,
    );

    // Add session to user's sessions subcollection
    await userDoc.collection('sessions').add(session.toFirestore());

    // Only update rewards for focus sessions
    if (sessionType == 'focus') {
      // Get current user data
      final userData = await userDoc.get();
      final data = userData.data() as Map<String, dynamic>;

      final currentTotalMinutes = data['totalFocusMinutes'] ?? 0;
      final currentStreak = data['currentStreak'] ?? 0;
      final longestStreak = data['longestStreak'] ?? 0;
      final lastSessionDate =
          data['lastSessionDate'] != null
              ? (data['lastSessionDate'] as Timestamp).toDate()
              : null;

      // Calculate new values
      final newTotalMinutes = currentTotalMinutes + duration;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      int newStreak = currentStreak;
      if (lastSessionDate == null) {
        newStreak = 1;
      } else if (_isSameDay(lastSessionDate, today)) {
        // Already had a session today, keep current streak
        newStreak = currentStreak;
      } else if (_isSameDay(lastSessionDate, yesterday)) {
        // Consecutive day, increment streak
        newStreak = currentStreak + 1;
      } else {
        // Streak broken, start over
        newStreak = 1;
      }

      final newLongestStreak =
          newStreak > longestStreak ? newStreak : longestStreak;

      // Check for level up
      final oldLevel = UserLevel.getUserLevel(currentTotalMinutes);
      final newLevel = UserLevel.getUserLevel(newTotalMinutes);
      final leveledUp = newLevel.level > oldLevel.level;

      // Update user document
      await userDoc.update({
        'totalFocusMinutes': newTotalMinutes,
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'lastSessionDate': Timestamp.fromDate(today),
        'level': newLevel.level,
        'lastUpdated': FieldValue.serverTimestamp(),
        // Store latest focus score if available
        if (focusScore != null) 'lastFocusScore': focusScore,
      });

      // Send notifications
      await NotificationService.showSessionCompleteNotification(
        title: '✅ Focus Session Complete!',
        body:
            focusScore != null
                ? 'Great job! You focused for $duration minutes with a ${(focusScore * 100).toInt()}% focus score.'
                : 'Great job! You focused for $duration minutes.',
      );

      if (newStreak > 1 && newStreak % 7 == 0) {
        await NotificationService.showStreakNotification(newStreak);
      }

      if (leveledUp) {
        await NotificationService.showLevelUpNotification(
          newTitle: newLevel.title,
          newLevel: newLevel.level,
        );
      }
    }
  }

  // Check if user has completed a session today
  static Future<bool> hasSessionToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sessions =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('sessions')
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
            .where('status', isEqualTo: 'completed')
            .where('type', isEqualTo: 'focus')
            .get();

    return sessions.docs.isNotEmpty;
  }

  // Get user's session history with unified model
  static Stream<List<FocusSession>> getUserSessions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FocusSession.fromFirestore(doc))
                  .toList(),
        );
  }

  // Helper method to check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
