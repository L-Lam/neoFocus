import 'package:cloud_firestore/cloud_firestore.dart';

// New enums for FocusStateManager
enum FocusSessionType { focus, shortBreak, longBreak }

enum FocusSessionStatus { active, paused, completed, abandoned }

// Old enums for backward compatibility
enum SessionType { focus, shortBreak, longBreak }

enum SessionStatus { notStarted, inProgress, paused, completed, cancelled }

// Main FocusSession class that works with both old and new code
class FocusSession {
  final String id;
  final String userId;
  final SessionType type; // Using old enum for compatibility
  final SessionStatus status; // Using old enum for compatibility
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pausedAt;
  final int duration; // in minutes (for old code compatibility)
  final int elapsedSeconds;
  final List<String> blockedApps;
  final int pomodoroCount;
  final String? notes;

  // New fields for FocusStateManager
  final int? plannedDuration; // in minutes
  final int? actualDuration; // in seconds
  final List<String>? distractingApps;
  final int? distractionCount;
  final double? focusScore;

  FocusSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.pausedAt,
    required this.duration,
    required this.elapsedSeconds,
    required this.blockedApps,
    required this.pomodoroCount,
    this.notes,
    // Optional new fields
    this.plannedDuration,
    this.actualDuration,
    this.distractingApps,
    this.distractionCount,
    this.focusScore,
  });

  // Constructor for FocusStateManager compatibility
  FocusSession.forStateManager({
    required this.id,
    required this.userId,
    required FocusSessionType focusType,
    required FocusSessionStatus focusStatus,
    required this.startTime,
    this.endTime,
    required int plannedDuration,
    required int actualDuration,
    required List<String> distractingApps,
    required int distractionCount,
    required double focusScore,
    this.notes,
  }) : type = _convertToSessionType(focusType),
       status = _convertToSessionStatus(focusStatus),
       duration = plannedDuration,
       elapsedSeconds = actualDuration,
       blockedApps = distractingApps,
       pomodoroCount = 0,
       this.plannedDuration = plannedDuration,
       this.actualDuration = actualDuration,
       this.distractingApps = distractingApps,
       this.distractionCount = distractionCount,
       this.focusScore = focusScore,
       pausedAt = null;

  factory FocusSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SessionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => SessionType.focus,
      ),
      status: SessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SessionStatus.notStarted,
      ),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime:
          data['endTime'] != null
              ? (data['endTime'] as Timestamp).toDate()
              : null,
      pausedAt:
          data['pausedAt'] != null
              ? (data['pausedAt'] as Timestamp).toDate()
              : null,
      duration: data['duration'] ?? data['plannedDuration'] ?? 25,
      elapsedSeconds: data['elapsedSeconds'] ?? data['actualDuration'] ?? 0,
      blockedApps: List<String>.from(
        data['blockedApps'] ?? data['distractingApps'] ?? [],
      ),
      pomodoroCount: data['pomodoroCount'] ?? 0,
      notes: data['notes'],
      // New fields
      plannedDuration: data['plannedDuration'],
      actualDuration: data['actualDuration'],
      distractingApps:
          data['distractingApps'] != null
              ? List<String>.from(data['distractingApps'])
              : null,
      distractionCount: data['distractionCount'],
      focusScore: data['focusScore']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'duration': duration,
      'elapsedSeconds': elapsedSeconds,
      'blockedApps': blockedApps,
      'pomodoroCount': pomodoroCount,
      'notes': notes,
      // Include new fields if present
      if (plannedDuration != null) 'plannedDuration': plannedDuration,
      if (actualDuration != null) 'actualDuration': actualDuration,
      if (distractingApps != null) 'distractingApps': distractingApps,
      if (distractionCount != null) 'distractionCount': distractionCount,
      if (focusScore != null) 'focusScore': focusScore,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Alias for FocusStateManager compatibility
  Map<String, dynamic> toMap() => toFirestore();

  FocusSession copyWith({
    SessionStatus? status,
    FocusSessionStatus? focusStatus,
    int? elapsedSeconds,
    DateTime? endTime,
    DateTime? pausedAt,
    String? notes,
    int? actualDuration,
    List<String>? distractingApps,
    int? distractionCount,
    double? focusScore,
  }) {
    return FocusSession(
      id: id,
      userId: userId,
      type: type,
      status:
          focusStatus != null
              ? _convertToSessionStatus(focusStatus)
              : (status ?? this.status),
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      pausedAt: pausedAt ?? this.pausedAt,
      duration: duration,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      blockedApps: blockedApps,
      pomodoroCount: pomodoroCount,
      notes: notes ?? this.notes,
      plannedDuration: plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      distractingApps: distractingApps ?? this.distractingApps,
      distractionCount: distractionCount ?? this.distractionCount,
      focusScore: focusScore ?? this.focusScore,
    );
  }

  // Helper methods for type conversion
  static SessionType _convertToSessionType(FocusSessionType type) {
    switch (type) {
      case FocusSessionType.focus:
        return SessionType.focus;
      case FocusSessionType.shortBreak:
        return SessionType.shortBreak;
      case FocusSessionType.longBreak:
        return SessionType.longBreak;
    }
  }

  static SessionStatus _convertToSessionStatus(FocusSessionStatus status) {
    switch (status) {
      case FocusSessionStatus.active:
        return SessionStatus.inProgress;
      case FocusSessionStatus.paused:
        return SessionStatus.paused;
      case FocusSessionStatus.completed:
        return SessionStatus.completed;
      case FocusSessionStatus.abandoned:
        return SessionStatus.cancelled;
    }
  }

  // Getters for FocusStateManager compatibility
  FocusSessionType get focusType {
    switch (type) {
      case SessionType.focus:
        return FocusSessionType.focus;
      case SessionType.shortBreak:
        return FocusSessionType.shortBreak;
      case SessionType.longBreak:
        return FocusSessionType.longBreak;
    }
  }

  FocusSessionStatus get focusStatus {
    switch (status) {
      case SessionStatus.notStarted:
      case SessionStatus.inProgress:
        return FocusSessionStatus.active;
      case SessionStatus.paused:
        return FocusSessionStatus.paused;
      case SessionStatus.completed:
        return FocusSessionStatus.completed;
      case SessionStatus.cancelled:
        return FocusSessionStatus.abandoned;
    }
  }

  // Helper method to check if session was completed
  bool get completed => status == SessionStatus.completed;

  // Helper to get session type as string for backward compatibility
  String get sessionType {
    switch (type) {
      case SessionType.focus:
        return 'focus';
      case SessionType.shortBreak:
        return 'break';
      case SessionType.longBreak:
        return 'longBreak';
    }
  }
}
