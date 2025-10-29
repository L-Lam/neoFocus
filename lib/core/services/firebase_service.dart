// Replace lib/core/services/firebase_service.dart with this version
import '/core/services/task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'elo_service.dart';

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

  // Initialize user document in Firestore
  static Future<void> initializeUserDocument(User user) async {
    final userDoc = users.doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // New user - create document with ELO fields
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Focus Hero',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'level': 1,
        'totalFocusMinutes': 0,
        'totalXP': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'achievements': [],
        // ELO fields
        'eloRating': 1200,
        'eloRank': 'Bronze',
        'peakElo': 1200,
        'eloHistory': [],
        'lastEloUpdate': FieldValue.serverTimestamp(),
        // Preferences
        'preferences': {
          'focusDuration': 25,
          'breakDuration': 5,
          'longBreakDuration': 15,
          'notificationsEnabled': true,
        },
      });
    } else {
      // Existing user - update last login and sync display name
      final userData = docSnapshot.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      // Sync display name from Firebase Auth if it exists
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final currentDisplayName = userData['displayName'];

        // Update if Firestore has no display name or it's the default
        if (currentDisplayName == null ||
            currentDisplayName == 'Focus Hero' ||
            currentDisplayName.isEmpty) {
          updates['displayName'] = user.displayName;
        }
      }

      // Add ELO fields if missing (for existing users)
      if (!userData.containsKey('eloRating')) {
        updates['eloRating'] = 1200;
        updates['eloRank'] = 'Bronze';
        updates['peakElo'] = 1200;
        updates['eloHistory'] = [];
        updates['lastEloUpdate'] = FieldValue.serverTimestamp();
      }

      await userDoc.update(updates);

      // Check for daily ELO update
      try {
        // Import dynamically to avoid circular dependencies
        // final EloService = (await import('elo_service.dart')).EloService;
        await EloService.scheduleDailyEloUpdate(user.uid);
      } catch (e) {
        print('ELO daily update check error: $e');
      }
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
