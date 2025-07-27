class SessionStats {
  final int totalSessions;
  final int totalFocusMinutes;
  final int todaySessions;
  final int todayFocusMinutes;
  final int weekSessions;
  final int weekFocusMinutes;
  final double averageSessionLength;
  final int completionRate;
  final Map<String, int> sessionsByType;

  SessionStats({
    required this.totalSessions,
    required this.totalFocusMinutes,
    required this.todaySessions,
    required this.todayFocusMinutes,
    required this.weekSessions,
    required this.weekFocusMinutes,
    required this.averageSessionLength,
    required this.completionRate,
    required this.sessionsByType,
  });

  factory SessionStats.empty() {
    return SessionStats(
      totalSessions: 0,
      totalFocusMinutes: 0,
      todaySessions: 0,
      todayFocusMinutes: 0,
      weekSessions: 0,
      weekFocusMinutes: 0,
      averageSessionLength: 0,
      completionRate: 0,
      sessionsByType: {'focus': 0, 'shortBreak': 0, 'longBreak': 0},
    );
  }
}
