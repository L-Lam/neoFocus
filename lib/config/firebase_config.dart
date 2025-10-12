import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> initializeFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBk1fTybmth6cdx994F8J2nWM2Vxvy1CH0',
        authDomain: 'chatapp-5dbc6.firebaseapp.com',
        projectId: 'chatapp-5dbc6',
        storageBucket: 'chatapp-5dbc6.appspot.com',
        messagingSenderId: '979991129824',
        appId: '1:979991129824:web:6e0b4d7d8aa89c0297aa85',
        measurementId: 'G-7TJ5L6DHBE',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Enable Firestore offline persistence
  if (!kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      print('Firestore settings error: $e');
    }
  }
}

// Firebase service instances
final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;