import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../core/services/firebase_service.dart';

class EloService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // ELO Constants
  static const int _initialElo = 1200;
  static const int _kFactor = 32; // How much ratings can change
  static const double _focusGoalMinutes = 90.0; // Daily goal

  // Initialize ELO for new users
  static Future<void> initializeUserElo(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'eloRating': _initialElo,
      'eloHistory': [],
      'peakElo': _initialElo,
      'eloRank': _getEloRank(_initialElo),
    });
  }

  // Update ELO after daily focus performance
  static Future<void> updateDailyElo(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentElo = userData['eloRating'] ?? _initialElo;

    // Get today's focus minutes
    final todayMinutes = await _getTodayFocusMinutes(userId);

    // Calculate performance score (0 to 1)
    final performance = (todayMinutes / _focusGoalMinutes).clamp(0.0, 1.5);

    // Calculate expected performance based on current ELO
    final expectedPerformance = _getExpectedPerformance(currentElo);

    // Calculate new ELO
    final newElo = _calculateNewElo(
        currentElo,
        performance,
        expectedPerformance
    );

    // Update user document
    await _firestore.collection('users').doc(userId).update({
      'eloRating': newElo,
      'eloHistory': FieldValue.arrayUnion([{
        'date': Timestamp.now(),
        'oldElo': currentElo,
        'newElo': newElo,
        'focusMinutes': todayMinutes,
        'performance': performance,
      }]),
      'peakElo': max(newElo, userData['peakElo'] ?? _initialElo),
      'eloRank': _getEloRank(newElo),
      'lastEloUpdate': Timestamp.now(),
    });

    // Check for rank achievements
    await _checkEloAchievements(userId, currentElo, newElo);
  }

  // Update ELO after completing a focus session
  static Future<void> updateSessionElo(String userId, int sessionMinutes) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final currentElo = userData['eloRating'] ?? _initialElo;

    // Small ELO boost for completing sessions
    final sessionBonus = (sessionMinutes / 25.0 * 5).round(); // 5 points per pomodoro
    final newElo = currentElo + sessionBonus;

    await _firestore.collection('users').doc(userId).update({
      'eloRating': newElo,
      'peakElo': max(newElo, userData['peakElo'] ?? _initialElo),
      'eloRank': _getEloRank(newElo),
    });
  }

  // Calculate new ELO rating
  static int _calculateNewElo(
      int currentElo,
      double actualPerformance,
      double expectedPerformance
      ) {
    final scoreDifference = actualPerformance - expectedPerformance;
    final eloChange = (_kFactor * scoreDifference).round();

    // Prevent ELO from going below 800
    return max(800, currentElo + eloChange);
  }

  // Get expected performance based on ELO
  static double _getExpectedPerformance(int elo) {
    // Higher ELO = higher expectations
    if (elo < 1000) return 0.3; // 27 minutes expected
    if (elo < 1200) return 0.5; // 45 minutes expected
    if (elo < 1400) return 0.7; // 63 minutes expected
    if (elo < 1600) return 0.9; // 81 minutes expected
    if (elo < 1800) return 1.0; // 90 minutes expected
    if (elo < 2000) return 1.1; // 99 minutes expected
    return 1.2; // 108 minutes expected for elite players
  }

  // Get today's focus minutes
  static Future<double> _getTodayFocusMinutes(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sessions = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .where('type', isEqualTo: 'focus')
        .get();

    double totalMinutes = 0;
    for (var doc in sessions.docs) {
      final data = doc.data();
      totalMinutes += (data['actualDuration'] ?? data['duration'] ?? 0).toDouble();
    }

    return totalMinutes;
  }

  // Get ELO rank based on rating
  static String _getEloRank(int elo) {
    if (elo < 1000) return 'Bronze';
    if (elo < 1200) return 'Silver';
    if (elo < 1400) return 'Gold';
    if (elo < 1600) return 'Platinum';
    if (elo < 1800) return 'Diamond';
    if (elo < 2000) return 'Master';
    if (elo < 2200) return 'Grandmaster';
    return 'Legend';
  }

  // Get rank color
  static Color getEloRankColor(String rank) {
    switch (rank) {
      case 'Bronze': return const Color(0xFFCD7F32);
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Platinum': return const Color(0xFFE5E4E2);
      case 'Diamond': return const Color(0xFFB9F2FF);
      case 'Master': return const Color(0xFF9370DB);
      case 'Grandmaster': return const Color(0xFFFF4500);
      case 'Legend': return const Color(0xFFFF0000);
      default: return const Color(0xFF808080);
    }
  }

  // Get rank icon
  static String getEloRankIcon(String rank) {
    switch (rank) {
      case 'Bronze': return '🥉';
      case 'Silver': return '🥈';
      case 'Gold': return '🥇';
      case 'Platinum': return '💎';
      case 'Diamond': return '💠';
      case 'Master': return '👑';
      case 'Grandmaster': return '🏆';
      case 'Legend': return '🌟';
      default: return '📈';
    }
  }

  // Check for ELO achievements
  static Future<void> _checkEloAchievements(
      String userId,
      int oldElo,
      int newElo
      ) async {
    final achievements = <String>[];

    // Check rank promotions
    final oldRank = _getEloRank(oldElo);
    final newRank = _getEloRank(newElo);

    if (oldRank != newRank && _isRankHigher(newRank, oldRank)) {
      achievements.add('rank_${newRank.toLowerCase()}');

      // Special achievement for reaching Legend
      if (newRank == 'Legend') {
        achievements.add('legend_status');
      }
    }

    // Check milestones
    final milestones = [1000, 1200, 1400, 1600, 1800, 2000, 2200];
    for (final milestone in milestones) {
      if (oldElo < milestone && newElo >= milestone) {
        achievements.add('elo_$milestone');
      }
    }

    // Add achievements to user
    if (achievements.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'achievements': FieldValue.arrayUnion(achievements),
      });
    }
  }

  // Check if rank1 is higher than rank2
  static bool _isRankHigher(String rank1, String rank2) {
    final ranks = [
      'Bronze', 'Silver', 'Gold', 'Platinum',
      'Diamond', 'Master', 'Grandmaster', 'Legend'
    ];
    return ranks.indexOf(rank1) > ranks.indexOf(rank2);
  }

  // Get ELO leaderboard
  static Stream<List<Map<String, dynamic>>> getEloLeaderboard({int limit = 50}) {
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

    final higherRankedUsers = await _firestore
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