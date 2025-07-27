import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int level;
  final int totalFocusMinutes;
  final int currentStreak;
  final int longestStreak;
  final List<String> achievements;
  final UserPreferences preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
    required this.level,
    required this.totalFocusMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.achievements,
    required this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Focus Hero',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      level: map['level'] ?? 1,
      totalFocusMinutes: map['totalFocusMinutes'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      achievements: List<String>.from(map['achievements'] ?? []),
      preferences: UserPreferences.fromMap(
        map['preferences'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'level': level,
      'totalFocusMinutes': totalFocusMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'achievements': achievements,
      'preferences': preferences.toMap(),
    };
  }

  UserModel copyWith({
    String? displayName,
    DateTime? lastLoginAt,
    int? level,
    int? totalFocusMinutes,
    int? currentStreak,
    int? longestStreak,
    List<String>? achievements,
    UserPreferences? preferences,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      level: level ?? this.level,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      achievements: achievements ?? this.achievements,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserPreferences {
  final int focusDuration;
  final int breakDuration;
  final int longBreakDuration;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final List<String> blockedApps;
  final List<String> blockedWebsites;

  UserPreferences({
    required this.focusDuration,
    required this.breakDuration,
    required this.longBreakDuration,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.blockedApps,
    required this.blockedWebsites,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      focusDuration: map['focusDuration'] ?? 25,
      breakDuration: map['breakDuration'] ?? 5,
      longBreakDuration: map['longBreakDuration'] ?? 15,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      blockedWebsites: List<String>.from(map['blockedWebsites'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'focusDuration': focusDuration,
      'breakDuration': breakDuration,
      'longBreakDuration': longBreakDuration,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'blockedApps': blockedApps,
      'blockedWebsites': blockedWebsites,
    };
  }

  UserPreferences copyWith({
    int? focusDuration,
    int? breakDuration,
    int? longBreakDuration,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    List<String>? blockedApps,
    List<String>? blockedWebsites,
  }) {
    return UserPreferences(
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
    );
  }
}
