import 'dart:math';

class EloRating {
  final int rating;
  final int weeklyFocusMinutes; // Focus minutes in the last 7 days
  final DateTime lastRatingUpdate; // When rating was last calculated
  final DateTime lastActiveDate; // Last time user completed a session
  final int peakRating;
  final List<int> weeklyHistory; // Last 10 weeks of focus minutes
  final List<int> ratingHistory; // Last 10 rating changes

  EloRating({
    required this.rating,
    required this.weeklyFocusMinutes,
    required this.lastRatingUpdate,
    required this.lastActiveDate,
    required this.peakRating,
    List<int>? weeklyHistory,
    List<int>? ratingHistory,
  }) : weeklyHistory = weeklyHistory ?? <int>[],
       ratingHistory = ratingHistory ?? <int>[];

  factory EloRating.initial() {
    final now = DateTime.now();
    return EloRating(
      rating: 1000, // Starting ELO
      weeklyFocusMinutes: 0,
      lastRatingUpdate: now,
      lastActiveDate: now,
      peakRating: 1000,
      weeklyHistory: <int>[],
      ratingHistory: <int>[],
    );
  }

  factory EloRating.fromMap(Map<String, dynamic> map) {
    // Ensure map is not null and has basic structure
    if (map.isEmpty) return EloRating.initial();

    return EloRating(
      rating: map['rating'] ?? 1000,
      weeklyFocusMinutes: map['weeklyFocusMinutes'] ?? 0,
      lastRatingUpdate:
          map['lastRatingUpdate'] != null
              ? DateTime.parse(map['lastRatingUpdate'])
              : DateTime.now(),
      lastActiveDate:
          map['lastActiveDate'] != null
              ? DateTime.parse(map['lastActiveDate'])
              : DateTime.now(),
      peakRating: map['peakRating'] ?? (map['rating'] ?? 1000),
      weeklyHistory:
          map['weeklyHistory'] != null && map['weeklyHistory'] is List
              ? List<int>.from(map['weeklyHistory'])
              : null, // Let constructor handle null
      ratingHistory:
          map['ratingHistory'] != null && map['ratingHistory'] is List
              ? List<int>.from(map['ratingHistory'])
              : null, // Let constructor handle null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'weeklyFocusMinutes': weeklyFocusMinutes,
      'lastRatingUpdate': lastRatingUpdate.toIso8601String(),
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'peakRating': peakRating,
      'weeklyHistory': weeklyHistory,
      'ratingHistory': ratingHistory,
    };
  }

  // Get latest rating change for display
  String get ratingChangeIndicator {
    if (ratingHistory.isEmpty) return '±0';
    final latest = ratingHistory.last;
    return latest >= 0 ? '+$latest' : '$latest';
  }

  // Check if user has been inactive for more than a month
  bool get isLongTimeInactive {
    final now = DateTime.now();
    final daysSinceActive = now.difference(lastActiveDate).inDays;
    return daysSinceActive > 30;
  }

  // Get average weekly focus time
  double get averageWeeklyFocus {
    if (weeklyHistory.isEmpty) return weeklyFocusMinutes.toDouble();
    final total = weeklyHistory.reduce((a, b) => a + b) + weeklyFocusMinutes;
    return total / (weeklyHistory.length + 1);
  }

  EloRating copyWith({
    int? rating,
    int? weeklyFocusMinutes,
    DateTime? lastRatingUpdate,
    DateTime? lastActiveDate,
    int? peakRating,
    List<int>? weeklyHistory,
    List<int>? ratingHistory,
  }) {
    return EloRating(
      rating: rating ?? this.rating,
      weeklyFocusMinutes: weeklyFocusMinutes ?? this.weeklyFocusMinutes,
      lastRatingUpdate: lastRatingUpdate ?? this.lastRatingUpdate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      peakRating: peakRating ?? this.peakRating,
      weeklyHistory: weeklyHistory ?? this.weeklyHistory,
      ratingHistory: ratingHistory ?? this.ratingHistory,
    );
  }
}

// Weekly ELO Calculation System
class WeeklyEloCalculator {
  // Rating thresholds based on weekly focus minutes
  static const Map<int, int> weeklyFocusToRating = {
    0: 800, // 0 minutes = 800 rating
    60: 1000, // 1 hour = 1000 rating
    120: 1200, // 2 hours = 1200 rating
    180: 1400, // 3 hours = 1400 rating
    240: 1600, // 4 hours = 1600 rating
    300: 1800, // 5 hours = 1800 rating
    420: 2000, // 7 hours = 2000 rating
    600: 2200, // 10 hours = 2200 rating
    840: 2400, // 14 hours = 2400 rating
    1200: 2600, // 20 hours = 2600 rating
    1680: 2800, // 28 hours = 2800 rating
    2100: 3000, // 35 hours = 3000 rating
    2520: 3200, // 42 hours = 3200 rating
    3000: 3400, // 50 hours = 3400 rating
    3600: 3600, // 60 hours = 3600 rating
    4200: 3800, // 70 hours = 3800 rating
    5000: 4000, // 83+ hours = 4000 rating (max)
  };

  // Calculate new rating based on weekly focus time
  static EloRating calculateWeeklyRating(
    EloRating currentRating,
    int weeklyFocusMinutes,
  ) {
    // Calculate target rating based on focus time
    int targetRating = _getRatingFromFocusTime(weeklyFocusMinutes);

    // Apply smoothing to prevent dramatic rating swings
    int newRating = _applySmoothTransition(currentRating.rating, targetRating);

    // Apply protection for long-time inactive players
    if (currentRating.isLongTimeInactive && newRating < currentRating.rating) {
      int ratingDrop = currentRating.rating - newRating;
      int protectedDrop = (ratingDrop * 0.5).round(); // 50% reduction
      newRating = currentRating.rating - protectedDrop;
    }

    // Ensure rating doesn't go below minimum
    newRating = newRating.clamp(800, 4000);

    // Calculate rating change
    int ratingChange = newRating - currentRating.rating;

    // Update peak rating
    int newPeakRating = max(currentRating.peakRating, newRating);

    // Update weekly history (keep last 10 weeks)
    List<int> newWeeklyHistory = List.from(currentRating.weeklyHistory);
    newWeeklyHistory.add(currentRating.weeklyFocusMinutes);
    if (newWeeklyHistory.length > 10) {
      newWeeklyHistory.removeAt(0);
    }

    // Update rating history (keep last 10 changes)
    List<int> newRatingHistory = List.from(currentRating.ratingHistory);
    newRatingHistory.add(ratingChange);
    if (newRatingHistory.length > 10) {
      newRatingHistory.removeAt(0);
    }

    return EloRating(
      rating: newRating,
      weeklyFocusMinutes: weeklyFocusMinutes,
      lastRatingUpdate: DateTime.now(),
      lastActiveDate: DateTime.now(),
      peakRating: newPeakRating,
      weeklyHistory: newWeeklyHistory,
      ratingHistory: newRatingHistory,
    );
  }

  // Update weekly focus time when user completes a session
  static EloRating updateWeeklyFocus(
    EloRating currentRating,
    int sessionMinutes,
  ) {
    return currentRating.copyWith(
      weeklyFocusMinutes: currentRating.weeklyFocusMinutes + sessionMinutes,
      lastActiveDate: DateTime.now(),
    );
  }

  // Reset weekly focus time (called every week)
  static EloRating resetWeeklyFocus(EloRating currentRating) {
    return currentRating.copyWith(weeklyFocusMinutes: 0);
  }

  // Get target rating from focus time using interpolation
  static int _getRatingFromFocusTime(int focusMinutes) {
    // Find the two closest thresholds
    List<int> thresholds = weeklyFocusToRating.keys.toList()..sort();

    // If below minimum, return minimum rating
    if (focusMinutes <= thresholds.first) {
      return weeklyFocusToRating[thresholds.first]!;
    }

    // If above maximum, return maximum rating
    if (focusMinutes >= thresholds.last) {
      return weeklyFocusToRating[thresholds.last]!;
    }

    // Find the range and interpolate
    for (int i = 0; i < thresholds.length - 1; i++) {
      int lowerThreshold = thresholds[i];
      int upperThreshold = thresholds[i + 1];

      if (focusMinutes >= lowerThreshold && focusMinutes <= upperThreshold) {
        int lowerRating = weeklyFocusToRating[lowerThreshold]!;
        int upperRating = weeklyFocusToRating[upperThreshold]!;

        // Linear interpolation
        double ratio =
            (focusMinutes - lowerThreshold) / (upperThreshold - lowerThreshold);
        return (lowerRating + (upperRating - lowerRating) * ratio).round();
      }
    }

    return 1000; // Fallback
  }

  // Apply smooth transition to prevent dramatic rating changes
  static int _applySmoothTransition(int currentRating, int targetRating) {
    int difference = targetRating - currentRating;

    // Limit rating change to maximum of 200 points per week
    if (difference.abs() > 200) {
      if (difference > 0) {
        return currentRating + 200;
      } else {
        return currentRating - 200;
      }
    }

    return targetRating;
  }

  // Check if it's time for weekly rating update
  static bool shouldUpdateRating(EloRating currentRating) {
    final now = DateTime.now();
    final daysSinceUpdate =
        now.difference(currentRating.lastRatingUpdate).inDays;
    return daysSinceUpdate >= 7;
  }

  // Get expected focus time for target rating
  static int getFocusTimeForRating(int targetRating) {
    List<MapEntry<int, int>> entries = weeklyFocusToRating.entries.toList();

    for (int i = 0; i < entries.length - 1; i++) {
      if (targetRating >= entries[i].value &&
          targetRating <= entries[i + 1].value) {
        // Linear interpolation to find focus time
        double ratio =
            (targetRating - entries[i].value) /
            (entries[i + 1].value - entries[i].value);
        return (entries[i].key + (entries[i + 1].key - entries[i].key) * ratio)
            .round();
      }
    }

    return 300; // Default 5 hours
  }
}
