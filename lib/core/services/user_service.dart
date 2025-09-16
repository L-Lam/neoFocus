import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/elo_rating.dart';
import 'firebase_service.dart';

class UserService extends ChangeNotifier {
  UserModel? _currentUser;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  UserModel? get currentUser => _currentUser;

  UserService() {
    _initializeUserListener();
  }

  void _initializeUserListener() {
    FirebaseService.auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToUserChanges(user.uid);
      } else {
        _currentUser = null;
        _userSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _listenToUserChanges(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseService.firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            _currentUser = UserModel.fromMap(
              snapshot.data() as Map<String, dynamic>,
            );
            notifyListeners();
          }
        });
  }

  // Load user data (for compatibility with existing code)
  Future<void> loadUser(String uid) async {
    try {
      final doc =
          await FirebaseService.firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    await FirebaseService.firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .update(data);
  }

  // Update user profile
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await updateUserData(updates);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Update user preferences (overloaded for compatibility)
  Future<void> updatePreferences({
    required String uid,
    required UserPreferences preferences,
  }) async {
    await updateUserData({'preferences': preferences.toMap()});
  }

  Future<void> updateSinglePreference(String key, dynamic value) async {
    if (_currentUser == null) return;

    await FirebaseService.firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .update({'preferences.$key': value});
  }

  Future<void> addBlockedApp(String appName) async {
    if (_currentUser == null) return;

    final updatedApps = List<String>.from(_currentUser!.preferences.blockedApps)
      ..add(appName);

    await updateSinglePreference('blockedApps', updatedApps);
  }

  Future<void> removeBlockedApp(String appName) async {
    if (_currentUser == null) return;

    final updatedApps = List<String>.from(_currentUser!.preferences.blockedApps)
      ..remove(appName);

    await updateSinglePreference('blockedApps', updatedApps);
  }

  Future<void> addBlockedWebsite(String website) async {
    if (_currentUser == null) return;

    final updatedWebsites = List<String>.from(
      _currentUser!.preferences.blockedWebsites,
    )..add(website);

    await updateSinglePreference('blockedWebsites', updatedWebsites);
  }

  Future<void> removeBlockedWebsite(String website) async {
    if (_currentUser == null) return;

    final updatedWebsites = List<String>.from(
      _currentUser!.preferences.blockedWebsites,
    )..remove(website);

    await updateSinglePreference('blockedWebsites', updatedWebsites);
  }

  Future<void> updateStats({
    int? totalFocusMinutes,
    int? currentStreak,
    int? longestStreak,
    int? level,
    int? totalXP,
  }) async {
    if (_currentUser == null) return;

    final updates = <String, dynamic>{};
    if (totalFocusMinutes != null) {
      updates['totalFocusMinutes'] = totalFocusMinutes;
    }
    if (currentStreak != null) updates['currentStreak'] = currentStreak;
    if (longestStreak != null) updates['longestStreak'] = longestStreak;

    if (updates.isNotEmpty) {
      await updateUserData(updates);
    }
  }

  // Update ELO rating
  Future<void> updateEloRating(EloRating newRating) async {
    if (_currentUser == null) return;

    final updates = <String, dynamic>{'eloRating': newRating.toMap()};

    await updateUserData(updates);
  }

  // Add focus minutes to weekly total
  Future<void> addWeeklyFocusTime(int minutes) async {
    final user = _currentUser;
    if (user == null) return;

    // Update weekly focus time
    final updatedRating = WeeklyEloCalculator.updateWeeklyFocus(
      user.eloRating,
      minutes,
    );

    await updateEloRating(updatedRating);

    // Check if it's time for weekly rating update
    if (WeeklyEloCalculator.shouldUpdateRating(updatedRating)) {
      await _performWeeklyRatingUpdate();
    }
  }

  // Perform weekly rating calculation
  Future<void> _performWeeklyRatingUpdate() async {
    final user = _currentUser;
    if (user == null) return;

    // Calculate new rating based on weekly focus time
    final newRating = WeeklyEloCalculator.calculateWeeklyRating(
      user.eloRating,
      user.eloRating.weeklyFocusMinutes,
    );

    // Reset weekly focus time for next week
    final resetRating = WeeklyEloCalculator.resetWeeklyFocus(newRating);

    await updateEloRating(resetRating);
  }

  // Manual weekly rating update (can be called by admin or scheduled job)
  Future<void> forceWeeklyRatingUpdate() async {
    await _performWeeklyRatingUpdate();
  }

  // Get user statistics stream
  Stream<Map<String, dynamic>> getUserStats(String uid) {
    return FirebaseService.firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final data = doc.data() ?? {};
          return {
            'level': data['level'] ?? 1,
            'totalXP': data['totalXP'] ?? 0,
            'totalFocusMinutes': data['totalFocusMinutes'] ?? 0,
            'currentStreak': data['currentStreak'] ?? 0,
            'longestStreak': data['longestStreak'] ?? 0,
            'completedSessions': data['completedSessions'] ?? 0,
            'totalTasks': data['totalTasks'] ?? 0,
          };
        });
  }

  // Reset user progress (dangerous action)
  Future<void> resetProgress(String uid) async {
    try {
      await FirebaseService.firestore.collection('users').doc(uid).update({
        'level': 1,
        'totalXP': 0,
        'totalFocusMinutes': 0,
        'currentStreak': 0,
        'completedSessions': 0,
        'totalTasks': 0,
      });

      // Delete all tasks
      final tasksSnapshot =
          await FirebaseService.firestore
              .collection('users')
              .doc(uid)
              .collection('tasks')
              .get();

      final batch = FirebaseService.firestore.batch();
      for (final doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete all achievements
      final achievementsSnapshot =
          await FirebaseService.firestore
              .collection('users')
              .doc(uid)
              .collection('achievements')
              .get();

      final achievementsBatch = FirebaseService.firestore.batch();
      for (final doc in achievementsSnapshot.docs) {
        achievementsBatch.delete(doc.reference);
      }
      await achievementsBatch.commit();

      // Reload user data
      await loadUser(uid);
    } catch (e) {
      print('Error resetting progress: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
