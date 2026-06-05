import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:sda_youth_app/notifications_helper.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =====================================================
  // ✅ CORE WRITE
  // =====================================================

  static Future<void> createNotification({
    required String targetUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // ✅ Prevent self notifications
    if (currentUser?.uid == targetUid) return;

    try {
      await _db
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .add({
            'type': type,
            'title': title,
            'body': body,
            'senderId': currentUser?.uid,
            'senderName': currentUser?.displayName ?? 'Someone',
            'metadata': metadata ?? {},
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st);
      }
      debugPrint("Notification error: $e");
    }
  }

  // =====================================================
  // ✅ FOLLOW NOTIFICATION ✅ NEW
  // =====================================================

  static Future<void> notifyFollow({
    required String targetUid,
    required String followerName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == targetUid) return;

    await createNotification(
      targetUid: targetUid,
      type: 'follow',
      title: 'New follower',
      body: '$followerName started following you',
      metadata: {'senderId': user.uid},
    );
  }

  // =====================================================
  // ✅ LIKE
  // =====================================================

  static void notifyReaction({
    required String ownerUid,
    required String postId,
    required String reactorName,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || ownerUid == user.uid) return;

    createNotification(
      targetUid: ownerUid,
      type: 'like',
      title: 'New like',
      body: '$reactorName liked your post',
      metadata: {'postId': postId, 'senderId': user.uid},
    );

    NotificationsHelper.sendReactionNotification(
      postOwnerId: ownerUid,
      reactorId: user.uid,
      reactorName: reactorName,
      postId: postId,
      reaction: "👍",
    ).catchError((_) {});
  }

  // =====================================================
  // ✅ COMMENT
  // =====================================================

  static void notifyComment({
    required String ownerUid,
    required String postId,
    required String commenterName,
    required String text,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || ownerUid == user.uid) return;

    createNotification(
      targetUid: ownerUid,
      type: 'comment',
      title: 'New comment',
      body: '$commenterName: $text',
      metadata: {'postId': postId, 'senderId': user.uid},
    );

    NotificationsHelper.sendCommentNotification(
      postOwnerId: ownerUid,
      commenterId: user.uid,
      commenterName: commenterName,
      postId: postId,
      commentText: text,
    ).catchError((_) {});
  }

  // =====================================================
  // ✅ POST
  // =====================================================

  static void notifyNewPost({
    required String targetUid,
    required String postId,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    createNotification(
      targetUid: targetUid,
      type: 'post',
      title: 'New post',
      body: 'A new post is available',
      metadata: {'postId': postId, 'senderId': user.uid},
    );

    NotificationsHelper.sendPostNotification(
      toUserId: targetUid,
      fromUserId: user.uid,
      postId: postId,
    ).catchError((_) {});
  }

  // =====================================================
  // ✅ STREAM
  // =====================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> stream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // =====================================================
  // ✅ MARK READ
  // =====================================================

  static Future<void> markAllAsRead(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}
