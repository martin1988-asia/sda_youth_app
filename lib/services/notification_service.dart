// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sda_youth_app/notifications_helper.dart';

/// Notification Architecture — World-Class Alert Orchestrator for SDA Youth.
/// Manages digital identity tokens and real-time community transmission signals.
class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TOKEN GOVERNANCE ---

  /// Registers a unique device token to the user's secure identity ledger.
  /// Handles multi-device synchronization and platform-specific metadata.
  static Future<void> registerIdentityToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token.isEmpty) return;

    try {
      final tokenRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token);

      await tokenRef.set({
        'token': token,
        'platform': kIsWeb ? 'web' : 'mobile',
        'lastSynchronized': FieldValue.serverTimestamp(),
        'active': true,
      }, SetOptions(merge: true));
      
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, reason: 'Identity token registration failed');
      }
    }
  }

  /// Revokes an identity token (usually during session termination).
  static Future<void> revokeIdentityToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || token.isEmpty) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token)
          .delete();
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Retrieves all authorized transmission tokens for a specific identity.
  static Future<List<String>> fetchAuthorizedTokens(String userId) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .get();

      return snap.docs
          .map((d) => d.data()['token']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      return [];
    }
  }

  // --- TRANSMISSION WRAPPERS (High-Fidelity UI Triggers) ---

  /// Transmits a Peer Connection request alert.
  static Future<void> notifyFriendRequest({
    required String targetUid,
    required String requesterName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await NotificationsHelper.sendFriendRequestNotification(
      toUserId: targetUid,
      fromUserId: user.uid,
      fromUserName: requesterName,
    );
  }

  /// Transmits a Reaction/Interaction signal (Like).
  static Future<void> notifyReaction({
    required String ownerUid,
    required String postId,
    required String reactorName,
    String reactionType = "👍",
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await NotificationsHelper.sendReactionNotification(
      postOwnerId: ownerUid,
      reactorId: user.uid,
      reactorName: reactorName,
      postId: postId,
      reaction: reactionType,
    );
  }

  /// Transmits a Discussion signal (Comment).
  static Future<void> notifyComment({
    required String ownerUid,
    required String postId,
    required String commenterName,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await NotificationsHelper.sendCommentNotification(
      postOwnerId: ownerUid,
      commenterId: user.uid,
      commenterName: commenterName,
      postId: postId,
      commentText: text,
    );
  }

  /// Transmits a New Content alert to a specific recipient.
  static Future<void> notifyNewPost({
    required String targetUid,
    required String postId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await NotificationsHelper.sendPostNotification(
      toUserId: targetUid,
      fromUserId: user.uid,
      postId: postId,
    );
  }

  /// Transmits a General System or Community alert.
  static Future<void> notifyGeneral({
    required String targetUid,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    await NotificationsHelper.sendGeneralNotification(
      userId: targetUid,
      title: title,
      body: body,
      data: metadata,
    );
  }
}
