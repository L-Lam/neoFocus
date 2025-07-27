class UserLevel {
  final int level;
  final String title;
  final int minFocusMinutes;
  final String description;
  final String badge;

  const UserLevel({
    required this.level,
    required this.title,
    required this.minFocusMinutes,
    required this.description,
    required this.badge,
  });

  static const List<UserLevel> levels = [
    UserLevel(
      level: 1,
      title: 'Newbie',
      minFocusMinutes: 0,
      description: 'Just starting your focus journey',
      badge: '🌱',
    ),
    UserLevel(
      level: 5,
      title: 'Apprentice',
      minFocusMinutes: 300, // 5 hours
      description: 'Learning the ways of focus',
      badge: '📚',
    ),
    UserLevel(
      level: 10,
      title: 'Practitioner',
      minFocusMinutes: 1200, // 20 hours
      description: 'Developing focus habits',
      badge: '🎯',
    ),
    UserLevel(
      level: 20,
      title: 'Adept',
      minFocusMinutes: 3600, // 60 hours
      description: 'Mastering concentration',
      badge: '🏆',
    ),
    UserLevel(
      level: 30,
      title: 'Expert',
      minFocusMinutes: 7200, // 120 hours
      description: 'Focus comes naturally',
      badge: '💎',
    ),
    UserLevel(
      level: 40,
      title: 'Master',
      minFocusMinutes: 12000, // 200 hours
      description: 'Exceptional focus abilities',
      badge: '🌟',
    ),
    UserLevel(
      level: 50,
      title: 'Grandmaster',
      minFocusMinutes: 18000, // 300 hours
      description: 'Legendary concentration',
      badge: '👑',
    ),
    UserLevel(
      level: 75,
      title: 'Sage',
      minFocusMinutes: 36000, // 600 hours
      description: 'Wisdom through focus',
      badge: '🧙',
    ),
    UserLevel(
      level: 100,
      title: 'Enlightened',
      minFocusMinutes: 60000, // 1000 hours
      description: 'Transcendent focus mastery',
      badge: '🌞',
    ),
  ];

  static UserLevel getUserLevel(int totalMinutes) {
    UserLevel currentLevel = levels.first;

    for (final level in levels) {
      if (totalMinutes >= level.minFocusMinutes) {
        currentLevel = level;
      } else {
        break;
      }
    }

    return currentLevel;
  }

  static UserLevel? getNextLevel(int totalMinutes) {
    final currentLevel = getUserLevel(totalMinutes);
    final currentIndex = levels.indexOf(currentLevel);

    if (currentIndex < levels.length - 1) {
      return levels[currentIndex + 1];
    }

    return null;
  }

  static double getLevelProgress(int totalMinutes) {
    final currentLevel = getUserLevel(totalMinutes);
    final nextLevel = getNextLevel(totalMinutes);

    if (nextLevel == null) return 1.0;

    final progressMinutes = totalMinutes - currentLevel.minFocusMinutes;
    final requiredMinutes =
        nextLevel.minFocusMinutes - currentLevel.minFocusMinutes;

    return (progressMinutes / requiredMinutes).clamp(0.0, 1.0);
  }
}
