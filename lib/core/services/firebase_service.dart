// Replace lib/core/services/firebase_service.dart with this version
import 'package:cat/core/services/task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // User collection reference
  static CollectionReference get users => firestore.collection('users');

  // Get current user document
  static DocumentReference? get currentUserDoc {
    final user = auth.currentUser;
    if (user != null) {
      return users.doc(user.uid);
    }
    return null;
  }

  // In your FirebaseService.initializeUserDocument method, ensure all fields are included:

  static Future<void> initializeUserDocument(User user) async {
    final userDoc = users.doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'Focus Hero',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'level': 1,
        'totalXP': 0,
        'totalFocusMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'achievements': [],
        'photoUrl': null,
        'bio': null,
        'preferences': {
          'focusDuration': 25,
          'breakDuration': 5,
          'longBreakDuration': 15,
          'notificationsEnabled': true,
          'soundEnabled': true,
          'vibrationEnabled': true,
          'darkModeEnabled': false,
          'focusReminderTime': '09:00',
          'blockedApps': [],
          'blockedWebsites': [],
        },
      });

      // Initialize tasks collection with a welcome task
      final taskService = TaskService();
      await taskService.initializeTasksCollection(user.uid);
    } else {
      // Update existing user to ensure all fields exist
      final data = docSnapshot.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{};

      // Add lastLoginAt
      updates['lastLoginAt'] = FieldValue.serverTimestamp();

      // Ensure preferences have all required fields
      final currentPrefs = data['preferences'] as Map<String, dynamic>? ?? {};
      final updatedPrefs = {
        'focusDuration': currentPrefs['focusDuration'] ?? 25,
        'breakDuration': currentPrefs['breakDuration'] ?? 5,
        'longBreakDuration': currentPrefs['longBreakDuration'] ?? 15,
        'notificationsEnabled': currentPrefs['notificationsEnabled'] ?? true,
        'soundEnabled': currentPrefs['soundEnabled'] ?? true,
        'vibrationEnabled': currentPrefs['vibrationEnabled'] ?? true,
        'darkModeEnabled': currentPrefs['darkModeEnabled'] ?? false,
        'focusReminderTime': currentPrefs['focusReminderTime'] ?? '09:00',
        'blockedApps': currentPrefs['blockedApps'] ?? [],
        'blockedWebsites': currentPrefs['blockedWebsites'] ?? [],
      };
      updates['preferences'] = updatedPrefs;

      // Ensure all numeric fields exist
      if (data['totalXP'] == null) updates['totalXP'] = 0;
      if (data['bio'] == null) updates['bio'] = null;
      if (data['photoUrl'] == null) updates['photoUrl'] = null;

      await userDoc.update(updates);
    }
  }

  // Get user data once
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      print('🔍 Fetching user data for $uid');
      final doc = await users.doc(uid).get();

      if (doc.exists) {
        print('✅ User data found');
        return doc.data() as Map<String, dynamic>;
      } else {
        print('⚠️ User document not found');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
      return null;
    }
  }
}
