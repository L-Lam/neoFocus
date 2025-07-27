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
      return Stream.value(
        AnalyticsData(
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
        ),
      );
    }

    // Combine user data and sessions streams
    return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data() ?? {};

      // Get sessions
      final sessionsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('sessions')
              .orderBy('completedAt', descending: true)
              .get();

      return AnalyticsData.fromFirestore(
        userData,
        sessionsSnapshot.docs,
        period,
      );
    });
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
    } else {
      insights.add(
        'Build your habit by focusing more regularly. Current consistency: ${analytics.consistency.toStringAsFixed(0)}%.',
      );
    }

    // Streak insight
    if (analytics.currentStreak > 0) {
      insights.add(
        'You\'re on a ${analytics.currentStreak}-day streak! Keep it going!',
      );
    } else {
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
    if (analytics.averageDailyFocus > 120) {
      insights.add(
        'Amazing! You average ${analytics.averageDailyFocus.toStringAsFixed(0)} minutes of focus per day.',
      );
    } else if (analytics.averageDailyFocus > 60) {
      insights.add(
        'You average ${analytics.averageDailyFocus.toStringAsFixed(0)} minutes daily. Try to reach 2 hours!',
      );
    } else {
      insights.add(
        'Increase your daily focus time. Currently averaging ${analytics.averageDailyFocus.toStringAsFixed(0)} minutes.',
      );
    }

    return insights;
  }

  // Add a test session for demonstration
  Future<void> addTestSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final session = {
      'startedAt': Timestamp.fromDate(
        now.subtract(const Duration(minutes: 25)),
      ),
      'completedAt': Timestamp.fromDate(now),
      'duration': 25,
      'category': 'Work',
      'type': 'pomodoro',
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .add(session);

    // Update user stats
    await _firestore.collection('users').doc(user.uid).update({
      'totalFocusMinutes': FieldValue.increment(25),
      'totalSessions': FieldValue.increment(1),
    });
  }
}
