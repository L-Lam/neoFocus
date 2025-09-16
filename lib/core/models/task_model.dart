import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime scheduledFor;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.scheduledFor,
  });

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt:
          map['completedAt'] != null
              ? (map['completedAt'] as Timestamp).toDate()
              : null,
      scheduledFor: (map['scheduledFor'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? scheduledFor,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }
}
