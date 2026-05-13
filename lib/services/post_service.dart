// lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sda_youth_app/notifications_helper.dart';

/// Post Architecture — World-Class Content Engine for SDA Youth.
/// Aligned with Firestore Security Rules and high-fidelity identity management.
class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRIVATE UTILITIES ---

  /// Internal helper to fetch current user metadata from the 'users' ledger.
  static Future<Map<String, String>> _getUserMetadata(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return {
        'name': (data['name'] ?? data['displayName'] ?? 'Mission Member').toString(),
        'photo': (data['photoUrl'] ?? data['photoURL'] ?? '').toString(),
      };
    } catch (e) {
      return {'name': 'Mission Member', 'photo': ''};
    }
  }

  // --- CONTENT CREATION & EDITING ---

  /// Creates a community post with verified identity metadata.
  static Future<DocumentReference<Map<String, dynamic>>?> createCommunityPost({
    required String content,
    String? imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final meta = await _getUserMetadata(user.uid);
      final now = FieldValue.serverTimestamp();

      final ref = await _db.collection('community_posts').add({
        'authorId': user.uid,
        'authorName': meta['name'],
        'authorPhoto': meta['photo'],
        'content': content,
        'mediaUrl': imageUrl,
        'mediaType': imageUrl != null ? 'image' : null,
        'imageUrl': imageUrl, // Legacy fallback
        'timestamp': now,
        'createdAt': now,
        'likeCount': 0,
        'commentCount': 0,
        'visibility': 'public',
        'isEdited': false,
      });

      _dispatchPostAlerts(ref.id, user.uid);
      return ref;
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st, reason: 'Post creation failed');
      return null;
    }
  }

  /// Updates post content if the user is the original author.
  static Future<void> editPost({required String postId, required String newContent}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ref = _db.collection('community_posts').doc(postId);
      final snap = await ref.get();
      if (snap.exists && snap.data()?['authorId'] == user.uid) {
        await ref.update({
          'content': newContent,
          'isEdited': true,
          'lastEditAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // --- INTERACTION ENGINE ---

  /// Toggles a 'Like' signal. Now stores user identity metadata within the like.
  static Future<void> toggleLikeOnPost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = _db.collection('community_posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    try {
      final existingLike = await likeRef.get();

      if (existingLike.exists) {
        await likeRef.delete();
        await postRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        final meta = await _getUserMetadata(user.uid);
        await likeRef.set({
          'userId': user.uid,
          'userName': meta['name'],
          'userPhoto': meta['photo'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        await postRef.update({'likeCount': FieldValue.increment(1)});

        final postSnap = await postRef.get();
        final ownerId = postSnap.data()?['authorId'];
        if (ownerId != null && ownerId != user.uid) {
          await NotificationsHelper.sendReactionNotification(
            postOwnerId: ownerId.toString(),
            reactorId: user.uid,
            reactorName: meta['name']!,
            postId: postId,
            reaction: "👍",
          );
        }
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Appends a comment using real identity metadata from Firestore.
  static Future<void> addCommentToPost({
    required String postId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final meta = await _getUserMetadata(user.uid);
      final postRef = _db.collection('community_posts').doc(postId);

      await postRef.collection('comments').add({
        'userId': user.uid,
        'userName': meta['name'],
        'userPhoto': meta['photo'],
        'comment': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await postRef.update({'commentCount': FieldValue.increment(1)});

      final postSnap = await postRef.get();
      final ownerId = postSnap.data()?['authorId'];
      if (ownerId != null && ownerId != user.uid) {
        await NotificationsHelper.sendCommentNotification(
          postOwnerId: ownerId.toString(),
          commenterId: user.uid,
          commenterName: meta['name']!,
          postId: postId,
          commentText: text,
        );
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // --- MAINTENANCE & DELETION ---

  /// Purges a post from the ledger. Author-only action.
  static Future<bool> purgePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final ref = _db.collection('community_posts').doc(postId);
      final snap = await ref.get();
      if (!snap.exists || snap.data()?['authorId'] != user.uid) return false;

      await ref.delete();
      return true;
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      return false;
    }
  }

  /// Deletes a specific comment if the user is the author.
  static Future<void> deleteComment(String postId, String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final commentRef = _db.collection('community_posts').doc(postId).collection('comments').doc(commentId);
      final snap = await commentRef.get();
      
      if (snap.exists && snap.data()?['userId'] == user.uid) {
        await commentRef.delete();
        await _db.collection('community_posts').doc(postId).update({
          'commentCount': FieldValue.increment(-1)
        });
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // --- DATA STREAMS ---

  static Stream<QuerySnapshot<Map<String, dynamic>>> postsStream({int limit = 20}) {
    return _db.collection('community_posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String postId) {
    return _db.collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> _dispatchPostAlerts(String postId, String authorId) async {
    try {
      final friendsSnap = await _db.collection('users').doc(authorId).collection('friends').get();
      for (final f in friendsSnap.docs) {
        await NotificationsHelper.sendPostNotification(
          toUserId: f.id,
          fromUserId: authorId,
          postId: postId,
        );
      }
    } catch (_) {}
  }
}
