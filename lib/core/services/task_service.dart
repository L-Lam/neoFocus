import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';

class TaskService extends ChangeNotifier {
  static const int maxDailyXPTasks = 5;
  static const int defaultXPReward = 10;

  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Initialize tasks collection for a user
  Future<void> initializeTasksCollection(String userId) async {
    // Check if tasks collection exists
    final tasksSnapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .limit(1)
            .get();

    // If no tasks exist, create a welcome task
    if (tasksSnapshot.docs.isEmpty) {
      await createTask(
        userId: userId,
        title: 'Welcome to Focus Hero Tasks!',
        description: 'Complete this task to earn your first XP',
        scheduledFor: DateTime.now(),
      );
    }
  }

  // Get user's tasks for a specific date - Using simple approach to avoid index issues
  Stream<List<Task>> getUserTasksForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Task.fromMap(doc.data(), doc.id))
                  .where((task) {
                    final taskDate = DateTime(
                      task.scheduledFor.year,
                      task.scheduledFor.month,
                      task.scheduledFor.day,
                    );
                    final selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                    );
                    return taskDate.isAtSameMomentAs(selectedDate);
                  })
                  .toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        );
  }

  // Get count of XP tasks created for a specific date
  Future<int> getXPTaskCountForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);

    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .get();

    // Filter in memory to avoid index issues
    final tasks =
        snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).where((
          task,
        ) {
          final taskDate = DateTime(
            task.scheduledFor.year,
            task.scheduledFor.month,
            task.scheduledFor.day,
          );
          final selectedDate = DateTime(date.year, date.month, date.day);
          return taskDate.isAtSameMomentAs(selectedDate) && task.givesXP;
        }).toList();

    return tasks.length;
  }

  // Get count of XP tasks created today
  Future<int> getXPTaskCountForToday(String userId) async {
    return getXPTaskCountForDate(userId, DateTime.now());
  }

  // Create a new task
  Future<void> createTask({
    required String userId,
    required String title,
    String? description,
    required DateTime scheduledFor,
    bool? forceNoXP,
  }) async {
    // Ensure we're working with start of day for consistency
    final scheduledDate = DateTime(
      scheduledFor.year,
      scheduledFor.month,
      scheduledFor.day,
    );

    // Check if we can give XP for this task
    int xpTaskCount = await getXPTaskCountForDate(userId, scheduledDate);
    bool canGiveXP = xpTaskCount < maxDailyXPTasks && forceNoXP != true;

    final task = {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': false,
      'givesXP': canGiveXP,
      'xpReward': canGiveXP ? defaultXPReward : 0,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'scheduledFor': Timestamp.fromDate(scheduledDate),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .add(task);
  }

  // Complete a task
  Future<void> completeTask(String userId, Task task) async {
    final batch = _firestore.batch();

    // Update task
    final taskRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id);

    batch.update(taskRef, {
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // If task gives XP, update user stats
    if (task.givesXP && !task.isCompleted) {
      final userRef = _firestore.collection('users').doc(userId);

      // Get current user data to calculate new level
      final userDoc = await userRef.get();
      final currentXP = userDoc.data()?['totalXP'] ?? 0;
      final currentLevel = userDoc.data()?['level'] ?? 1;
      final newXP = currentXP + task.xpReward;
      final newLevel = _calculateLevel(newXP);

      batch.update(userRef, {
        'totalXP': FieldValue.increment(task.xpReward),
        'level': newLevel,
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // Check if user leveled up
      if (newLevel > currentLevel) {
        // Add achievement for leveling up
        await _addLevelUpAchievement(userId, newLevel);
      }
    }

    await batch.commit();
  }

  // Uncomplete a task
  Future<void> uncompleteTask(String userId, Task task) async {
    final batch = _firestore.batch();

    // Update task
    final taskRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id);

    batch.update(taskRef, {'isCompleted': false, 'completedAt': null});

    // If task gave XP, remove it
    if (task.givesXP && task.isCompleted) {
      final userRef = _firestore.collection('users').doc(userId);

      // Get current user data to calculate new level
      final userDoc = await userRef.get();
      final currentXP = userDoc.data()?['totalXP'] ?? 0;
      final newXP = (currentXP - task.xpReward).clamp(0, double.infinity);
      final newLevel = _calculateLevel(newXP.toInt());

      batch.update(userRef, {
        'totalXP': FieldValue.increment(-task.xpReward),
        'level': newLevel,
      });
    }

    await batch.commit();
  }

  // Delete a task
  Future<void> deleteTask(String userId, String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Calculate level from XP
  int _calculateLevel(int xp) {
    // Simple level calculation: every 100 XP = 1 level
    return (xp / 100).floor() + 1;
  }

  // Add level up achievement
  Future<void> _addLevelUpAchievement(String userId, int newLevel) async {
    final achievement = {
      'type': 'level_up',
      'title': 'Level $newLevel Reached!',
      'description': 'You\'ve reached level $newLevel!',
      'unlockedAt': FieldValue.serverTimestamp(),
      'level': newLevel,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .add(achievement);
  }

  // Get level title based on level
  static String getLevelTitle(int level) {
    if (level <= 0) return 'Newbie';
    if (level <= 5) return 'Beginner';
    if (level <= 10) return 'Apprentice';
    if (level <= 20) return 'Focused';
    if (level <= 30) return 'Dedicated';
    if (level <= 40) return 'Committed';
    if (level <= 50) return 'Disciplined';
    if (level <= 60) return 'Master';
    if (level <= 70) return 'Expert';
    if (level <= 80) return 'Guru';
    if (level <= 90) return 'Sage';
    if (level <= 99) return 'Legend';
    return 'Enlightened';
  }
}
