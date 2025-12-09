import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/services/firebase_service.dart';

class EloService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ELO Constants
  static const int _initialElo = 1000;
  static const int eloDelta = 16; // How much ratings can change

  // Initialize ELO for new users
  static Future<void> initializeUserElo(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'eloRating': _initialElo,
      'eloHistory': [],
      'maxEloRating': _initialElo,
    });
  }

  // Update ELO after daily focus performance
  static Future<void> updateDailyElo(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentElo = userData['eloRating'] ?? _initialElo;

    final todayMinutes = await _getTodayFocusMinutes(userId);
    final expectedMinutes = _getExpectedPerformance(currentElo);

    // Performance is actual minutes vs expected minutes
    final performance = todayMinutes / expectedMinutes;

    // Debug logging
    print('=== ELO Update Debug ===');
    print('Current ELO: $currentElo');
    print('Today Minutes: $todayMinutes');
    print('Expected Minutes: $expectedMinutes');
    print('Performance Ratio: $performance');

    // Calculate new ELO
    final newElo = _calculateNewElo(currentElo, performance);
    final eloDelta = newElo - currentElo;
    final maxEloRating = max(newElo, userData['maxEloRating'] ?? _initialElo);

    print('New ELO: $newElo');
    print('ELO Delta: $eloDelta');
    print('=======================');

    // Update user document
    await _firestore.collection('users').doc(userId).update({
      'eloRating': newElo,
      'eloDelta': eloDelta,
      'maxEloRating': maxEloRating,
      'eloHistory': FieldValue.arrayUnion([
        {
          'date': Timestamp.now(),
          'oldElo': currentElo,
          'newElo': newElo,
          'focusMinutes': todayMinutes,
          'performance': performance,
        },
      ]),
      'lastEloUpdate': Timestamp.now(),
    });

    // Check for rank achievements
  }

  // Update ELO after completing a focus session
  static Future<void> updateSessionElo(
    String userId,
    int sessionMinutes,
  ) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentElo = userData['eloRating'] ?? _initialElo;

    // Small ELO boost for completing sessions
    final sessionBonus =
        (sessionMinutes / 25.0 * 5).round(); // 5 points per pomodoro
    final newElo = currentElo + sessionBonus;
    final maxEloRating = max(newElo, userData['maxEloRating'] ?? _initialElo);

    await _firestore.collection('users').doc(userId).update({
      'eloRating': newElo,
      'maxEloRating': maxEloRating,
    });
  }

  static int _calculateNewElo(int currentElo, double performance) {
    // Performance ratio: 1.0 = met expectations, >1.0 = exceeded, <1.0 = underperformed
    // Cap performance at 3.0 to prevent extreme swings
    final cappedPerformance = min(performance, 3.0);

    // Score difference: -1.0 to +2.0
    final scoreDifference = cappedPerformance - 1.0;

    // ELO change: -16 to +32
    final eloChange = (eloDelta * scoreDifference).round();

    return max(0, currentElo + eloChange);
  }

  // Get expected daily focus minutes based on ELO (piecewise function)
  static double _getExpectedPerformance(int elo) {
    if (elo >= 1000 && elo <= 3000) {
      return -1658.0 + 244.5 * log(elo.toDouble());
    } else {
      return 9.14 * pow(1.001165, elo.toDouble());
    }
  }

  // Get today's focus minutes
  static Future<double> _getTodayFocusMinutes(String userId) async {
    // First try to get from dailyFocusMinutes field
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final dailyMinutes = userDoc.data()?['dailyFocusMinutes'];
      if (dailyMinutes != null && dailyMinutes > 0) {
        return dailyMinutes.toDouble();
      }
    }

    // Fallback: calculate from today's sessions
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
            .get();

    double totalMinutes = 0;
    for (var doc in sessions.docs) {
      final data = doc.data();
      totalMinutes +=
          (data['actualDuration'] ?? data['duration'] ?? 0).toDouble();
    }

    return totalMinutes;
  }

  static String getEloRankTitle(int rating) {
    if (rating < 1000) {
      return 'Newbie';
    }
    if (rating < 1200) {
      return 'Apprentice';
    }
    if (rating < 1500) {
      return 'Locked-In';
    }
    if (rating < 1800) {
      return 'Scholar';
    }
    if (rating < 2100) {
      return 'Monk';
    }
    if (rating < 2400) {
      return 'Philosopher';
    }
    if (rating < 2700) {
      return 'The Thinker';
    }
    if (rating < 3000) {
      return 'Transcendent';
    }
    return 'Enlightened One';
  }

  static Color getEloRankColor(int rating) {
    if (rating < 1000) {
      return Colors.grey;
    }
    if (rating < 1200) {
      return Colors.green;
    }
    if (rating < 1500) {
      return Colors.deepPurple;
    }
    if (rating < 1800) {
      return Colors.indigo;
    }
    if (rating < 2100) {
      return Colors.greenAccent;
    }
    if (rating < 2400) {
      return Colors.orangeAccent;
    }
    if (rating < 2700) {
      return Colors.deepOrange;
    }
    if (rating < 3000) {
      return Colors.pinkAccent;
    }
    return Colors.red;
  }

  // Check for ELO achievements

  // Get ELO leaderboard
  static Stream<List<Map<String, dynamic>>> getEloLeaderboard({
    int limit = 50,
  }) {
    return _firestore
        .collection('users')
        .orderBy('eloRating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'displayName': data['displayName'] ?? 'Anonymous',
              'eloRating': data['eloRating'] ?? _initialElo,
              'eloRank': data['eloRank'] ?? 'Bronze',
              'level': data['level'] ?? 1,
              'totalFocusMinutes': data['totalFocusMinutes'] ?? 0,
            };
          }).toList();
        });
  }

  // Get user's ELO ranking position
  static Future<int> getUserEloRanking(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return -1;

    final userElo = userDoc.data()!['eloRating'] ?? _initialElo;

    final higherRankedUsers =
        await _firestore
            .collection('users')
            .where('eloRating', isGreaterThan: userElo)
            .count()
            .get();

    return higherRankedUsers.count! + 1;
  }

  // Schedule daily ELO update
  static Future<void> scheduleDailyEloUpdate(String userId) async {
    final lastUpdate = await _getLastEloUpdate(userId);
    final now = DateTime.now();

    // Check if it's a new day since last update
    if (lastUpdate == null ||
        lastUpdate.day != now.day ||
        lastUpdate.month != now.month ||
        lastUpdate.year != now.year) {
      await updateDailyElo(userId);
    }
  }

  // Get last ELO update time
  static Future<DateTime?> _getLastEloUpdate(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    final lastUpdate = userDoc.data()!['lastEloUpdate'] as Timestamp?;
    return lastUpdate?.toDate();
  }
}
