// lib/services/message_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sda_youth_app/notifications_helper.dart';

/// Message Service — aligned with Firestore rules & indexes.
/// Manages secure transmissions, conversation ledger, and inbox streams.
class MessageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // IDENTITY RESOLUTION
  // ---------------------------------------------------------------------------

  static Future<String?> resolveIdentityByEmail(String email) async {
    final key = email.trim().toLowerCase();
    if (key.isEmpty) {
      return null;
    }

    try {
      final snap = await _db
          .collection('user_lookup')
          .where('emailLower', isEqualTo: key)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return null;
      }
      return snap.docs.first.data()['uid']?.toString();
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'resolveIdentityByEmail failed',
        );
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // TRANSMISSION ENGINE
  // ---------------------------------------------------------------------------

  static Future<DocumentReference<Map<String, dynamic>>?> sendMessage({
    required String text,
    required String recipientEmail,
    bool draft = false,
  }) async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null) {
      return null;
    }

    try {
      final recipientId = await resolveIdentityByEmail(recipientEmail);

      if (!draft && (recipientId == null || recipientId.isEmpty)) {
        throw StateError('Target identity not found in user_lookup');
      }

      final messageId = _db.collection('messages').doc().id;
      final timestamp = FieldValue.serverTimestamp();

      final data = <String, Object?>{
        'messageId': messageId,
        'text': text,
        'senderId': sender.uid,
        'senderEmail': sender.email,
        'senderName': sender.displayName ?? 'Peer',
        'recipientId': recipientId,
        'recipientEmail': recipientEmail,
        'status': draft ? 'draft' : 'sent',
        'read': false,
        'timestamp': timestamp,
      };

      final ref = _db.collection('messages').doc(messageId);
      await ref.set(data);

      if (!draft && recipientId != null) {
        final convoId = _generateConvoId(sender.uid, recipientId);
        await _db.collection('conversations').doc(convoId).set({
          'participants': [sender.uid, recipientId],
          'lastMessage': text,
          'lastSenderId': sender.uid,
          'lastUpdated': timestamp,
          'unread': true,
        }, SetOptions(merge: true));

        if (recipientId != sender.uid) {
          await NotificationsHelper.sendGeneralNotification(
            userId: recipientId,
            title: "New Message",
            body: "${sender.displayName ?? 'A peer'} sent you a message",
            data: {"route": "/messages", "threadId": convoId},
          );
        }
      }

      return ref;
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'sendMessage failed',
        );
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // MAINTENANCE & ARCHIVING
  // ---------------------------------------------------------------------------

  static Future<void> markAsRead(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).update({'read': true});
    } catch (_) {
      // Silently fail if rules restrict updates.
    }
  }

  static Future<void> deleteMessage(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).delete();
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'deleteMessage failed',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TRANSMISSION STREAMS
  // ---------------------------------------------------------------------------

  /// Inbox stream — recipientId + status + timestamp (indexed).
  static Stream<QuerySnapshot<Map<String, dynamic>>> inboxStream(String uid) {
    return _db
        .collection('messages')
        .where('recipientId', isEqualTo: uid)
        .where('status', isEqualTo: 'sent')
        .orderBy('status')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Outbox stream — senderId + status + timestamp (indexed).
  static Stream<QuerySnapshot<Map<String, dynamic>>> outboxStream(String uid) {
    return _db
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'sent')
        .orderBy('status')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Drafts stream — senderId + status + timestamp.
  static Stream<QuerySnapshot<Map<String, dynamic>>> draftsStream(String uid) {
    return _db
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'draft')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // PRIVATE UTILITIES
  // ---------------------------------------------------------------------------

  static String _generateConvoId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }
}
