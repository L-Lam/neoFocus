import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../models/analytics_data.dart';

class AnalyticsService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  Stream<AnalyticsData> getAnalyticsData(String period) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(_getEmptyAnalytics());
    }

    // Combine user data and sessions streams
    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((
      userDoc,
    ) async {
      if (!userDoc.exists) {
        return _getEmptyAnalytics();
      }

      final userData = userDoc.data() ?? {};

      // Get sessions - handle both completedAt and startTime fields
      Query sessionsQuery = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions');

      // Try to order by completedAt first, if that fails, use startTime
      QuerySnapshot sessionsSnapshot;
      try {
        sessionsSnapshot =
            await sessionsQuery.orderBy('completedAt', descending: true).get();
      } catch (e) {
        // If completedAt doesn't exist, try startTime
        try {
          sessionsSnapshot =
              await sessionsQuery.orderBy('startTime', descending: true).get();
        } catch (e2) {
          // If neither exists, just get all sessions
          sessionsSnapshot = await sessionsQuery.get();
        }
      }

      // Filter out active sessions if they exist
      final completedSessions =
          sessionsSnapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isActive'] != true;
          }).toList();

      return AnalyticsData.fromFirestore(userData, completedSessions, period);
    });
  }

  AnalyticsData _getEmptyAnalytics() {
    return AnalyticsData(
      totalFocusMinutes: 0,
      currentStreak: 0,
      longestStreak: 0,
      totalSessions: 0,
      level: 1,
      consistency: 0,
      totalDays: 0,
      dailyFocusData: [],
      achievements: [],
      categoryBreakdown: {},
      averageDailyFocus: 0,
      bestDay: 0,
      mostProductiveTime: 'No data',
    );
  }

  List<String> generateInsights(AnalyticsData analytics) {
    final insights = <String>[];

    // Consistency insight
    if (analytics.consistency >= 80) {
      insights.add(
        'Excellent consistency! You\'re focusing ${analytics.consistency.toStringAsFixed(0)}% of days.',
      );
    } else if (analytics.consistency >= 50) {
      insights.add(
        'Good progress! Try to increase your consistency from ${analytics.consistency.toStringAsFixed(0)}% to 80%.',
      );
    } else if (analytics.totalSessions > 0) {
      insights.add(
        'Build your habit by focusing more regularly. Current consistency: ${analytics.consistency.toStringAsFixed(0)}%.',
      );
    } else {
      insights.add(
        'Start your focus journey today! Complete your first session to begin tracking your progress.',
      );
    }

    // Streak insight
    if (analytics.currentStreak > 0) {
      insights.add(
        'You\'re on a ${analytics.currentStreak}-day streak! Keep it going!',
      );
    } else if (analytics.longestStreak > 0) {
      insights.add(
        'Start a new streak today! Your longest streak was ${analytics.longestStreak} days.',
      );
    }

    // Best time insight
    if (analytics.mostProductiveTime != 'No data') {
      insights.add(
        'Your most productive time is ${analytics.mostProductiveTime}. Schedule important tasks then.',
      );
    }

    // Average focus insight
    if (analytics.totalSessions > 0) {
      if (analytics.averageDailyFocus > 120) {
        insights.add(
          'Amazing! You average ${analytics.averageDailyFocus.toStringAsFixed(0)} minutes of focus per day.',
        );
      } else if (analytics.averageDailyFocus > 60) {
        insights.add(
          'You average ${analytics.averageDailyFocus.toStringAsFixed(0)} minutes daily. Try to reach 2 hours!',
        );
      } else if (analytics.averageDailyFocus > 0) {
        insights.add(
          'Increase your daily focus time. Currently averaging ${analytics.averageDailyFocus.toStringAsFixed(0)} minutes.',
        );
      }
    }

    // Level progress insight
    if (analytics.level >= 5) {
      insights.add(
        'You\'ve reached Level ${analytics.level}! Keep up the excellent work.',
      );
    } else if (analytics.totalSessions > 0) {
      insights.add(
        'You\'re Level ${analytics.level}. Complete more sessions to level up!',
      );
    }

    return insights.isNotEmpty
        ? insights
        : [
          'Welcome to Focus Hero! Complete your first focus session to start seeing your analytics.',
          'Set a goal to focus for at least 25 minutes today.',
        ];
  }

  // Add a test session for demonstration
  Future<void> addTestSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startTime = now.subtract(const Duration(minutes: 25));

    final session = {
      'startTime': Timestamp.fromDate(startTime),
      'completedAt': Timestamp.fromDate(now),
      'duration': 25,
      'actualDuration': 25,
      'category': 'Work',
      'type': 'focus',
      'isActive': false,
      'wasCompleted': true,
      'earnedXP': 25,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .add(session);

    // Update user stats
    await _firestore.collection('users').doc(user.uid).update({
      'totalFocusMinutes': FieldValue.increment(25),
      'totalXP': FieldValue.increment(25),
      'totalSessions': FieldValue.increment(1),
    });
  }

  // Generate sample data for testing
  Future<void> generateSampleAnalyticsData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final random = Random();
    final now = DateTime.now();

    // Generate sessions for the past 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final sessionsPerDay = random.nextInt(4) + 1;

      for (int j = 0; j < sessionsPerDay; j++) {
        final hour = random.nextInt(14) + 7; // 7 AM to 9 PM
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          random.nextInt(60),
        );
        final duration = [25, 25, 25, 50, 90][random.nextInt(5)];

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .add({
              'startTime': Timestamp.fromDate(startTime),
              'completedAt': Timestamp.fromDate(
                startTime.add(Duration(minutes: duration)),
              ),
              'duration': duration,
              'actualDuration': duration,
              'category': ['Work', 'Study', 'Personal'][random.nextInt(3)],
              'type': 'focus',
              'isActive': false,
              'wasCompleted': true,
              'earnedXP': duration,
            });
      }
    }

    // Calculate total stats
    final sessionsSnapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .get();

    int totalMinutes = 0;
    int totalXP = 0;

    for (var doc in sessionsSnapshot.docs) {
      final data = doc.data();
      totalMinutes += (data['duration'] as int? ?? 0);
      totalXP += (data['earnedXP'] as int? ?? 0);
    }

    // Update user stats
    await _firestore.collection('users').doc(user.uid).update({
      'totalFocusMinutes': totalMinutes,
      'totalXP': totalXP,
      'totalSessions': sessionsSnapshot.docs.length,
      'currentStreak': random.nextInt(7) + 1,
      'longestStreak': random.nextInt(15) + 7,
      'level': (totalXP / 100).floor() + 1,
    });
  }
}
