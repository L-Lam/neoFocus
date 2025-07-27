import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String uid;
  final String displayName;
  final String email;
  final int level;
  final int totalFocusMinutes;
  final int currentStreak;
  final String? photoUrl;
  final DateTime? lastActiveAt;

  Friend({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.level,
    required this.totalFocusMinutes,
    required this.currentStreak,
    this.photoUrl,
    this.lastActiveAt,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? 'Unknown',
      email: map['email'] ?? '',
      level: map['level'] ?? 1,
      totalFocusMinutes: map['totalFocusMinutes'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      photoUrl: map['photoUrl'],
      lastActiveAt:
          map['lastActiveAt'] != null
              ? (map['lastActiveAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'level': level,
      'totalFocusMinutes': totalFocusMinutes,
      'currentStreak': currentStreak,
      'photoUrl': photoUrl,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }
}
