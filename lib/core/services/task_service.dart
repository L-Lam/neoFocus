import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';

class TaskService extends ChangeNotifier {
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
        description: 'Complete this task to get started',
        scheduledFor: DateTime.now(),
      );
    }
  }

  // Get user's tasks for a specific date
  Stream<List<Task>> getUserTasksForDate(String userId, DateTime date) {
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

  // Create a new task
  Future<void> createTask({
    required String userId,
    required String title,
    String? description,
    required DateTime scheduledFor,
  }) async {
    // Ensure we're working with start of day for consistency
    final scheduledDate = DateTime(
      scheduledFor.year,
      scheduledFor.month,
      scheduledFor.day,
    );

    final task = {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': false,
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
    final taskRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id);

    await taskRef.update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Uncomplete a task
  Future<void> uncompleteTask(String userId, Task task) async {
    final taskRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id);

    await taskRef.update({'isCompleted': false, 'completedAt': null});
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
}
