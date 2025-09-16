import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/elo_rating.dart';
import 'firebase_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseService.auth;
  User? _user;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await FirebaseService.initializeUserDocument(credential.user!);
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        // Update display name in Firebase Auth
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
        _user = _auth.currentUser;

        // Create user document in Firestore with the display name
        final userDoc = FirebaseService.users.doc(credential.user!.uid);
        await userDoc.set({
          'uid': credential.user!.uid,
          'email': email,
          'displayName': displayName, // Use the provided displayName directly
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'eloRating': 1000, // Start with 1000 ELO (Beginner rank)
          'totalFocusMinutes': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'achievements': [],
          'preferences': {
            'focusDuration': 25,
            'breakDuration': 5,
            'longBreakDuration': 15,
            'notificationsEnabled': true,
          },
        });
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
