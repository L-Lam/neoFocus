import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int dailyFocusMinutes;
  final int totalFocusMinutes;
  final int coins;
  final int maxEloRating;
  final int eloRating;
  final int eloDelta;
  final int totalAuraPoints;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;
  final String? bio;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.dailyFocusMinutes,
    required this.totalFocusMinutes,
    required this.coins,
    required this.maxEloRating,
    required this.eloRating,
    required this.eloDelta,
    required this.totalAuraPoints,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    this.bio,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp fields with null safety
    DateTime getTimestamp(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return defaultValue;
    }

    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Focus Hero',
      dailyFocusMinutes: map['dailyFocusMinutes'] ?? 0,
      totalFocusMinutes: map['totalFocusMinutes'] ?? 0,
      coins: map['coins'] ?? 0,
      maxEloRating: map['maxEloRating'] ?? 0,
      eloRating: map['eloRating'] ?? 0,
      eloDelta: map['eloDelta'] ?? 0,
      totalAuraPoints: map['totalAuraPoints'] ?? 0,
      createdAt: getTimestamp(map['createdAt'], DateTime.now()),
      lastLoginAt: getTimestamp(map['lastLoginAt'], DateTime.now()),
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      bio: map['bio'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'dailyFocusMinutes': dailyFocusMinutes,
      'totalFocusMinutes': totalFocusMinutes,
      'coins': coins,
      'maxEloRating': maxEloRating,
      'eloRating': eloRating,
      'eloDelta': eloDelta,
      'totalAuraPoints': totalAuraPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferences': preferences.toMap(),
      'bio': bio,
    };
  }
}

class UserPreferences {
  final int focusDuration;
  final int breakDuration;
  final int longBreakDuration;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool darkModeEnabled;
  final String focusReminderTime;

  UserPreferences({
    required this.focusDuration,
    required this.breakDuration,
    required this.longBreakDuration,
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.darkModeEnabled,
    required this.focusReminderTime,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      focusDuration: map['focusDuration'] ?? 25,
      breakDuration: map['breakDuration'] ?? 5,
      longBreakDuration: map['longBreakDuration'] ?? 15,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      darkModeEnabled: map['darkModeEnabled'] ?? false,
      focusReminderTime: map['focusReminderTime'] ?? '09:00',
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
      'darkModeEnabled': darkModeEnabled,
      'focusReminderTime': focusReminderTime,
    };
  }

  UserPreferences copyWith({
    int? focusDuration,
    int? breakDuration,
    int? longBreakDuration,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkModeEnabled,
    String? focusReminderTime,
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
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      focusReminderTime: focusReminderTime ?? this.focusReminderTime,
    );
  }
}