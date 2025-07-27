import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsData {
  final int totalFocusMinutes;
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final int level;
  final double consistency;
  final int totalDays;
  final List<DailyFocusData> dailyFocusData;
  final List<Achievement> achievements;
  final Map<String, int> categoryBreakdown;
  final double averageDailyFocus;
  final int bestDay;
  final String mostProductiveTime;

  AnalyticsData({
    required this.totalFocusMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSessions,
    required this.level,
    required this.consistency,
    required this.totalDays,
    required this.dailyFocusData,
    required this.achievements,
    required this.categoryBreakdown,
    required this.averageDailyFocus,
    required this.bestDay,
    required this.mostProductiveTime,
  });

  factory AnalyticsData.fromFirestore(
    Map<String, dynamic> userData,
    List<QueryDocumentSnapshot> sessions,
    String period,
  ) {
    // Process session data
    final dailyData = _processDailyData(sessions, period);
    final categoryData = _processCategoryData(sessions);
    final productiveTime = _findMostProductiveTime(sessions);

    return AnalyticsData(
      totalFocusMinutes: (userData['totalFocusMinutes'] ?? 0).toInt(),
      currentStreak: (userData['currentStreak'] ?? 0).toInt(),
      longestStreak: (userData['longestStreak'] ?? 0).toInt(),
      totalSessions: sessions.length,
      level: (userData['level'] ?? 1).toInt(),
      consistency: _calculateConsistency(dailyData),
      totalDays: dailyData.length,
      dailyFocusData: dailyData,
      achievements: _processAchievements(userData['achievements'] ?? []),
      categoryBreakdown: categoryData,
      averageDailyFocus: _calculateAverageFocus(dailyData),
      bestDay: _findBestDay(dailyData),
      mostProductiveTime: productiveTime,
    );
  }

  static List<DailyFocusData> _processDailyData(
    List<QueryDocumentSnapshot> sessions,
    String period,
  ) {
    final Map<String, int> dailyMinutes = {};
    final now = DateTime.now();

    // Determine date range based on period
    DateTime startDate;
    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    // Group sessions by day
    for (final session in sessions) {
      final data = session.data() as Map<String, dynamic>;
      final timestamp = (data['completedAt'] as Timestamp).toDate();

      if (timestamp.isAfter(startDate)) {
        final dateKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        final minutes = (data['duration'] ?? 0).toInt();
        // Fix: Explicitly cast to int
        dailyMinutes[dateKey] =
            ((dailyMinutes[dateKey] ?? 0) + minutes).toInt();
      }
    }

    // Create daily data list
    final List<DailyFocusData> dailyData = [];
    DateTime current = startDate;

    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      final dateKey =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      dailyData.add(
        DailyFocusData(date: current, minutes: dailyMinutes[dateKey] ?? 0),
      );
      current = current.add(const Duration(days: 1));
    }

    return dailyData;
  }

  static Map<String, int> _processCategoryData(
    List<QueryDocumentSnapshot> sessions,
  ) {
    final Map<String, int> categories = {
      'Work': 0,
      'Study': 0,
      'Personal': 0,
      'Other': 0,
    };

    for (final session in sessions) {
      final data = session.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'Other';
      final minutes = (data['duration'] ?? 0).toInt();
      // Fix: Explicitly cast to int
      categories[category] = ((categories[category] ?? 0) + minutes).toInt();
    }

    return categories;
  }

  static String _findMostProductiveTime(List<QueryDocumentSnapshot> sessions) {
    final Map<int, int> hourlyMinutes = {};

    for (final session in sessions) {
      final data = session.data() as Map<String, dynamic>;
      final timestamp = (data['startedAt'] as Timestamp).toDate();
      final hour = timestamp.hour;
      final minutes = (data['duration'] ?? 0).toInt();
      // Fix: Explicitly cast to int
      hourlyMinutes[hour] = ((hourlyMinutes[hour] ?? 0) + minutes).toInt();
    }

    if (hourlyMinutes.isEmpty) return 'No data';

    final mostProductiveHour =
        hourlyMinutes.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    if (mostProductiveHour < 12) {
      return '$mostProductiveHour:00 AM';
    } else if (mostProductiveHour == 12) {
      return '12:00 PM';
    } else {
      return '${mostProductiveHour - 12}:00 PM';
    }
  }

  static double _calculateConsistency(List<DailyFocusData> dailyData) {
    if (dailyData.isEmpty) return 0;

    final daysWithFocus = dailyData.where((d) => d.minutes > 0).length;
    return (daysWithFocus / dailyData.length) * 100;
  }

  static double _calculateAverageFocus(List<DailyFocusData> dailyData) {
    if (dailyData.isEmpty) return 0;

    final totalMinutes = dailyData.fold<int>(0, (sum, d) => sum + d.minutes);
    return totalMinutes / dailyData.length;
  }

  static int _findBestDay(List<DailyFocusData> dailyData) {
    if (dailyData.isEmpty) return 0;

    return dailyData.map((d) => d.minutes).reduce((a, b) => a > b ? a : b);
  }

  static List<Achievement> _processAchievements(List<dynamic> achievementIds) {
    return achievementIds
        .map((id) => Achievement.fromId(id.toString()))
        .toList();
  }
}

class DailyFocusData {
  final DateTime date;
  final int minutes;

  DailyFocusData({required this.date, required this.minutes});
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  factory Achievement.fromId(String id) {
    // Define all possible achievements
    final achievements = {
      'first_session': Achievement(
        id: 'first_session',
        title: 'First Step',
        description: 'Complete your first focus session',
        icon: Icons.flag,
        isUnlocked: true,
      ),
      'week_streak': Achievement(
        id: 'week_streak',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        isUnlocked: true,
      ),
      'focus_master': Achievement(
        id: 'focus_master',
        title: 'Focus Master',
        description: 'Complete 100 focus sessions',
        icon: Icons.psychology,
        isUnlocked: true,
      ),
      'early_bird': Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete a session before 7 AM',
        icon: Icons.wb_sunny,
        isUnlocked: true,
      ),
      'night_owl': Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Complete a session after 10 PM',
        icon: Icons.nightlight,
        isUnlocked: true,
      ),
      'marathon': Achievement(
        id: 'marathon',
        title: 'Marathon',
        description: 'Focus for 4 hours in a single day',
        icon: Icons.timer,
        isUnlocked: true,
      ),
    };

    return achievements[id] ??
        Achievement(
          id: id,
          title: 'Unknown',
          description: 'Unknown achievement',
          icon: Icons.help,
          isUnlocked: false,
        );
  }
}
