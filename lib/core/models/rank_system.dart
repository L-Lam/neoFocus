import 'package:flutter/material.dart';

class RankTier {
  final String name;
  final String badge;
  final Color color;
  final int minRating;
  final int maxRating;

  const RankTier({
    required this.name,
    required this.badge,
    required this.color,
    required this.minRating,
    required this.maxRating,
  });
}

class RankSystem {
  // Ranks based on weekly focus time (customize as needed)
  static const List<RankTier> ranks = [
    RankTier(
      name: 'Inactive',
      badge: '😴',
      color: Colors.black45,
      minRating: 0,
      maxRating: 999,
    ),
    RankTier(
      name: 'Beginner',
      badge: '🌱',
      color: Colors.grey,
      minRating: 1000,
      maxRating: 1199,
    ),
    RankTier(
      name: 'Focused',
      badge: '🎯',
      color: Colors.green,
      minRating: 1200,
      maxRating: 1399,
    ),
    RankTier(
      name: 'Locked-In',
      badge: '💪',
      color: Colors.blue,
      minRating: 1400,
      maxRating: 1699,
    ),
    RankTier(
      name: 'Big Brain',
      badge: '�',
      color: Colors.yellow,
      minRating: 1700,
      maxRating: 1999,
    ),
    RankTier(
      name: 'Sage',
      badge: '⚡',
      color: Colors.purple,
      minRating: 2000,
      maxRating: 2399,
    ),
    RankTier(
      name: 'Monk',
      badge: '🏆',
      color: Colors.orange,
      minRating: 2400,
      maxRating: 2699,
    ),
    RankTier(
      name: 'Philosopher',
      badge: '👑',
      color: Colors.pink,
      minRating: 2700,
      maxRating: 2999,
    ),
    RankTier(
      name: 'The Enlightened',
      badge: '🌟',
      color: Colors.red,
      minRating: 3000,
      maxRating: 10000,
    ),
  ];

  // Get rank tier from rating
  static RankTier getRankFromRating(int rating) {
    for (final rank in ranks) {
      if (rating >= rank.minRating && rating <= rank.maxRating) {
        return rank;
      }
    }
    // Fallback to highest rank if rating exceeds max
    return ranks.last;
  }

  // Get progress within current rank (0.0 to 1.0)
  static double getRankProgress(int rating) {
    final currentRank = getRankFromRating(rating);

    // If at max rank, return 1.0
    if (currentRank == ranks.last && rating >= currentRank.maxRating) {
      return 1.0;
    }

    final progress =
        (rating - currentRank.minRating) /
        (currentRank.maxRating - currentRank.minRating);
    return progress.clamp(0.0, 1.0);
  }

  // Get next rank tier
  static RankTier? getNextRank(int rating) {
    final currentRank = getRankFromRating(rating);
    final currentIndex = ranks.indexOf(currentRank);

    if (currentIndex < ranks.length - 1) {
      return ranks[currentIndex + 1];
    }

    return null; // Already at highest rank
  }

  // Get rating needed for next rank
  static int? getRatingForNextRank(int rating) {
    final nextRank = getNextRank(rating);
    return nextRank?.minRating;
  }

  static Color getRankColor(int rating) {
    final currentRank = getRankFromRating(rating);
    return currentRank.color;
  }
}
