import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class FollowService {
  static final _db = FirebaseFirestore.instance;

  // ✅ FOLLOW / UNFOLLOW
  static Future<void> toggleFollow(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;

    // ✅ Prevent self follow
    if (uid == targetUserId) return;

    final userRef = _db.collection('users');

    final followingRef = userRef
        .doc(uid)
        .collection('following')
        .doc(targetUserId);

    final followerRef = userRef
        .doc(targetUserId)
        .collection('followers')
        .doc(uid);

    try {
      final doc = await followingRef.get();

      if (doc.exists) {
        // =========================
        // ✅ UNFOLLOW
        // =========================
        await followingRef.delete();
        await followerRef.delete();

        await userRef.doc(uid).set({
          'followingCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));

        await userRef.doc(targetUserId).set({
          'followersCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      } else {
        // =========================
        // ✅ FOLLOW
        // =========================
        await followingRef.set({'timestamp': FieldValue.serverTimestamp()});

        await followerRef.set({'timestamp': FieldValue.serverTimestamp()});

        await userRef.doc(uid).set({
          'followingCount': FieldValue.increment(1),
        }, SetOptions(merge: true));

        await userRef.doc(targetUserId).set({
          'followersCount': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // ✅ FETCH FOLLOWER NAME SAFELY
        String followerName = 'Someone';

        try {
          final userDoc = await userRef.doc(uid).get();
          final data = userDoc.data();

          if (data != null &&
              data['name'] != null &&
              data['name'].toString().isNotEmpty) {
            followerName = data['name'];
          }
        } catch (_) {}

        // ✅ SEND NOTIFICATION (SAFE + FALLBACK)
        try {
          await NotificationService.notifyFollow(
            targetUid: targetUserId,
            followerName: followerName,
          );
        } catch (_) {
          try {
            await userRef.doc(targetUserId).collection('notifications').add({
              'type': 'follow',
              'fromUserId': uid,
              'followerName': followerName,
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });
          } catch (_) {
            // ignore
          }
        }
      }
    } catch (e) {
      // ✅ ✅ SAFE DEBUG LOG (NO ANALYZER WARNING)
      assert(() {
        debugPrint('Follow error: $e');
        return true;
      }());
    }
  }

  // ✅ CHECK IF FOLLOWING
  static Stream<bool> isFollowing(String targetUserId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
