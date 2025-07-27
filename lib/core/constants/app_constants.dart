class AppConstants {
  // App info
  static const String appName = 'Focus Hero';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String achievementsCollection = 'achievements';
  static const String challengesCollection = 'challenges';

  // Task system constants
  static const int dailyXPTaskLimit = 5; // Max tasks that give XP per day
  static const int taskXPReward = 10; // XP per completed task
  static const int maxTasksPerDay = 20; // Total tasks limit per day
  // Focus session defaults
  static const int defaultFocusDuration = 25; // minutes
  static const int defaultBreakDuration = 5; // minutes
  static const int defaultLongBreakDuration = 15; // minutes
  static const int sessionsUntilLongBreak = 4;

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // Padding and margins
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
}
