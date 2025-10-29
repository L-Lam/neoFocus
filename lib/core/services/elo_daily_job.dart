import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/elo_service.dart';

class EloDailyJob {
  static Timer? _dailyTimer;
  static bool _isRunning = false;

  // Start the daily ELO update job
  static void startDailyEloUpdates() {
    if (_dailyTimer != null) return;

    // Run immediately on start
    _runDailyUpdate();

    // Calculate time until next midnight
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      5,
    ); // 12:05 AM
    final timeUntilMidnight = tomorrow.difference(now);

    // Schedule first run at midnight
    Timer(timeUntilMidnight, () {
      _runDailyUpdate();

      // Then run every 24 hours
      _dailyTimer = Timer.periodic(const Duration(days: 1), (_) {
        _runDailyUpdate();
      });
    });
  }

  // Stop the daily job
  static void stopDailyEloUpdates() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
  }

  // Run the daily update for all users
  static Future<void> _runDailyUpdate() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      print('[ELO] Starting daily ELO update...');

      // Get all users who were active in the last 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final users =
          await FirebaseService.firestore
              .collection('users')
              .where(
                'lastLoginAt',
                isGreaterThan: Timestamp.fromDate(sevenDaysAgo),
              )
              .get();

      int updated = 0;

      for (final userDoc in users.docs) {
        try {
          await EloService.scheduleDailyEloUpdate(userDoc.id);
          updated++;
        } catch (e) {
          print('[ELO] Error updating user ${userDoc.id}: $e');
        }
      }

      print('[ELO] Daily update complete. Updated $updated users.');

      // Update global leaderboard stats
      await _updateLeaderboardStats();
    } catch (e) {
      print('[ELO] Daily update error: $e');
    } finally {
      _isRunning = false;
    }
  }

  // Update global leaderboard statistics
  static Future<void> _updateLeaderboardStats() async {
    try {
      // Get top 100 players
      final topPlayers =
          await FirebaseService.firestore
              .collection('users')
              .orderBy('eloRating', descending: true)
              .limit(100)
              .get();

      if (topPlayers.docs.isEmpty) return;

      // Calculate stats
      final stats = {
        'topElo': topPlayers.docs.first.data()['eloRating'],
        'top10Average': _calculateAverage(topPlayers.docs.take(10)),
        'top50Average': _calculateAverage(topPlayers.docs.take(50)),
        'top100Average': _calculateAverage(topPlayers.docs),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Store in a global stats document
      await FirebaseService.firestore
          .collection('global')
          .doc('elo_stats')
          .set(stats, SetOptions(merge: true));
    } catch (e) {
      print('[ELO] Leaderboard stats update error: $e');
    }
  }

  static int _calculateAverage(Iterable<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0;

    int sum = 0;
    int count = 0;

    for (final doc in docs) {
      final elo = doc.data() as Map<String, dynamic>?;
      if (elo != null && elo['eloRating'] != null) {
        sum += elo['eloRating'] as int;
        count++;
      }
    }

    return count > 0 ? (sum / count).round() : 0;
  }

  // Check if user needs ELO update (called when user logs in)
  static Future<void> checkUserEloUpdate(String userId) async {
    try {
      await EloService.scheduleDailyEloUpdate(userId);
    } catch (e) {
      print('[ELO] User update check error: $e');
    }
  }
}
