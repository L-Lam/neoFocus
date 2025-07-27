import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../models/friend_model.dart';
import '../models/challenge_model.dart';
import '../models/blog_post_model.dart';

class SocialService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final FirebaseAuth _auth = FirebaseService.auth;

  // Friend Management
  static Future<void> sendFriendRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    // Add to target user's friend requests
    batch.set(
      _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(currentUserId),
      {
        'fromUserId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      },
    );

    // Add to current user's sent requests
    batch.set(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('sentRequests')
          .doc(targetUserId),
      {
        'toUserId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      },
    );

    await batch.commit();
  }

  static Future<void> acceptFriendRequest(String fromUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    // Add to both users' friends lists
    batch.set(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(fromUserId),
      {'userId': fromUserId, 'timestamp': FieldValue.serverTimestamp()},
    );

    batch.set(
      _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(currentUserId),
      {'userId': currentUserId, 'timestamp': FieldValue.serverTimestamp()},
    );

    // Remove friend request
    batch.delete(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(fromUserId),
    );

    batch.delete(
      _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('sentRequests')
          .doc(currentUserId),
    );

    await batch.commit();
  }

  static Stream<List<Friend>> getFriends() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
          final friendIds =
              snapshot.docs.map((doc) => doc['userId'] as String).toList();

          if (friendIds.isEmpty) return [];

          final friendDocs =
              await _firestore
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: friendIds)
                  .get();

          return friendDocs.docs
              .map((doc) => Friend.fromMap({...doc.data(), 'uid': doc.id}))
              .toList();
        });
  }

  // Challenge Management
  static Future<String> createChallenge(Challenge challenge) async {
    final doc = await _firestore
        .collection('challenges')
        .add(challenge.toMap());

    // Add challenge to all participants
    for (final participantId in challenge.participants) {
      await _firestore
          .collection('users')
          .doc(participantId)
          .collection('activeChallenges')
          .doc(doc.id)
          .set({'challengeId': doc.id});
    }

    return doc.id;
  }

  static Future<void> joinChallenge(String challengeId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not logged in');

    try {
      // Check if challenge exists and is active
      final challengeDoc =
          await _firestore.collection('challenges').doc(challengeId).get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challengeData = challengeDoc.data()!;
      final status = challengeData['status'] as String;

      if (status != 'active') {
        throw Exception('Challenge is no longer active');
      }

      // Check if user is already a participant
      final participants = List<String>.from(
        challengeData['participants'] ?? [],
      );
      if (participants.contains(currentUserId)) {
        throw Exception('You are already participating in this challenge');
      }

      // Join the challenge
      await _firestore.collection('challenges').doc(challengeId).update({
        'participants': FieldValue.arrayUnion([currentUserId]),
        'participantProgress.$currentUserId': 0,
      });

      // Add to user's active challenges
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('activeChallenges')
          .doc(challengeId)
          .set({
            'challengeId': challengeId,
            'joinedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to join challenge: ${e.toString()}');
    }
  }

  static Future<void> updateChallengeProgress(
    String challengeId,
    int minutes,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('challenges').doc(challengeId).update({
      'participantProgress.$currentUserId': FieldValue.increment(minutes),
    });
  }

  static Stream<List<Challenge>> getActiveChallenges() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('challenges')
        .where('participants', arrayContains: currentUserId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Challenge.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Leaderboard
  static Stream<List<Friend>> getGlobalLeaderboard({int limit = 20}) {
    return _firestore
        .collection('users')
        .orderBy('totalFocusMinutes', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Friend.fromMap({...doc.data(), 'uid': doc.id}))
                  .toList(),
        );
  }

  static Stream<List<Friend>> getFriendsLeaderboard() {
    return getFriends().asyncMap((friends) async {
      friends.sort(
        (a, b) => b.totalFocusMinutes.compareTo(a.totalFocusMinutes),
      );
      return friends;
    });
  }

  // Blog/Community
  static Future<void> createBlogPost(BlogPost post) async {
    await _firestore.collection('blog_posts').add(post.toMap());
  }

  static Stream<List<BlogPost>> getBlogPosts({int limit = 20}) {
    return _firestore
        .collection('blog_posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BlogPost.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  static Future<void> likeBlogPost(String postId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final postRef = _firestore.collection('blog_posts').doc(postId);
    final doc = await postRef.get();

    if (doc.exists) {
      final likes = List<String>.from(doc.data()?['likes'] ?? []);

      if (likes.contains(currentUserId)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }

  static Future<void> addComment(String postId, Comment comment) async {
    await _firestore
        .collection('blog_posts')
        .doc(postId)
        .collection('comments')
        .add(comment.toMap());

    await _firestore.collection('blog_posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  static Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('blog_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Comment.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }
  // Add this method to the SocialService class:

  static Future<void> declineFriendRequest(String fromUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    // Remove friend request
    batch.delete(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friendRequests')
          .doc(fromUserId),
    );

    // Update sent request status
    batch.update(
      _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('sentRequests')
          .doc(currentUserId),
      {'status': 'declined'},
    );

    await batch.commit();
  }
}
