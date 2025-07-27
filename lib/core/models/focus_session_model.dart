import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType { focus, shortBreak, longBreak }

enum SessionStatus { notStarted, inProgress, paused, completed }

class FocusSession {
  final String id;
  final String userId;
  final SessionType type;
  final SessionStatus status;
  final int duration; // in minutes
  final int remainingSeconds;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? pausedAt;
  final int pomodoroCount; // Which pomodoro in the cycle (1-4)

  FocusSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.duration,
    required this.remainingSeconds,
    required this.startedAt,
    this.completedAt,
    this.pausedAt,
    required this.pomodoroCount,
  });

  factory FocusSession.fromMap(Map<String, dynamic> map, String id) {
    return FocusSession(
      id: id,
      userId: map['userId'] ?? '',
      type: SessionType.values.firstWhere(
        (e) => e.toString() == 'SessionType.${map['type']}',
        orElse: () => SessionType.focus,
      ),
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${map['status']}',
        orElse: () => SessionStatus.notStarted,
      ),
      duration: map['duration'] ?? 25,
      remainingSeconds: map['remainingSeconds'] ?? 0,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      completedAt:
          map['completedAt'] != null
              ? (map['completedAt'] as Timestamp).toDate()
              : null,
      pausedAt:
          map['pausedAt'] != null
              ? (map['pausedAt'] as Timestamp).toDate()
              : null,
      pomodoroCount: map['pomodoroCount'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'duration': duration,
      'remainingSeconds': remainingSeconds,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'pomodoroCount': pomodoroCount,
    };
  }

  FocusSession copyWith({
    String? id,
    String? userId,
    SessionType? type,
    SessionStatus? status,
    int? duration,
    int? remainingSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? pausedAt,
    int? pomodoroCount,
  }) {
    return FocusSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
    );
  }
}
