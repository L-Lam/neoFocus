import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType { daily, weekly, friend, group, seasonal }

enum ChallengeStatus { pending, active, completed, failed }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final int targetMinutes;
  final int currentMinutes;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants;
  final String createdBy;
  final Map<String, int> participantProgress;
  final String? winnerId;
  final int rewardPoints;
  final String? seasonalTheme;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.targetMinutes,
    required this.currentMinutes,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.createdBy,
    required this.participantProgress,
    this.winnerId,
    required this.rewardPoints,
    this.seasonalTheme,
  });

  factory Challenge.fromMap(Map<String, dynamic> map, String id) {
    return Challenge(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${map['type']}',
        orElse: () => ChallengeType.daily,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.toString() == 'ChallengeStatus.${map['status']}',
        orElse: () => ChallengeStatus.pending,
      ),
      targetMinutes: map['targetMinutes'] ?? 0,
      currentMinutes: map['currentMinutes'] ?? 0,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      participants: List<String>.from(map['participants'] ?? []),
      createdBy: map['createdBy'] ?? '',
      participantProgress: Map<String, int>.from(
        map['participantProgress'] ?? {},
      ),
      winnerId: map['winnerId'],
      rewardPoints: map['rewardPoints'] ?? 0,
      seasonalTheme: map['seasonalTheme'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'targetMinutes': targetMinutes,
      'currentMinutes': currentMinutes,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participants': participants,
      'createdBy': createdBy,
      'participantProgress': participantProgress,
      'winnerId': winnerId,
      'rewardPoints': rewardPoints,
      'seasonalTheme': seasonalTheme,
    };
  }
}
