// lib/services/message_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sda_youth_app/notifications_helper.dart';

/// Messaging Architecture — World-Class Communication Engine for SDA Youth.
/// Manages secure identity-to-identity transmissions and conversation ledgers.
///
/// Collections used:
/// - /user_lookup: { uid, emailLower } → resolveIdentityByEmail
/// - /messages:      individual transmissions
/// - /conversations: thread metadata for fast inbox loading
class MessageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // IDENTITY RESOLUTION
  // ---------------------------------------------------------------------------

  /// Resolves an e-mail signature to a unique identity UID
  /// using the /user_lookup ledger.
  static Future<String?> resolveIdentityByEmail(String email) async {
    final key = email.trim().toLowerCase();
    if (key.isEmpty) return null;

    try {
      final snap = await _db
          .collection('user_lookup')
          .where('emailLower', isEqualTo: key)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['uid']?.toString();
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Identity resolution failed',
        );
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // TRANSMISSION ENGINE
  // ---------------------------------------------------------------------------

  /// Transmits a secure message between identities.
  ///
  /// - [text] is the message body.
  /// - [recipientEmail] is used to resolve the target UID via /user_lookup.
  /// - If [draft] is true, the message is stored with status "draft" and no
  ///   conversation/unread metadata is updated.
  static Future<DocumentReference<Map<String, dynamic>>?> sendMessage({
    required String text,
    required String recipientEmail,
    bool draft = false,
  }) async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null) return null;

    try {
      final recipientId = await resolveIdentityByEmail(recipientEmail);

      if (!draft && (recipientId == null || recipientId.isEmpty)) {
        throw StateError('Target identity not found in community ledger');
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

      // 1. Store the primary transmission (top-level /messages)
      final ref = _db.collection('messages').doc(messageId);
      await ref.set(data);

      if (!draft && recipientId != null) {
        // 2. Update the Conversation Ledger (fast inbox)
        final convoId = _generateConvoId(sender.uid, recipientId);
        await _db.collection('conversations').doc(convoId).set(
          {
            'participants': [sender.uid, recipientId],
            'lastMessage': text,
            'lastSenderId': sender.uid,
            'lastUpdated': timestamp,
            'unread': true,
          },
          SetOptions(merge: true),
        );

        // 3. Transmit Push/System Alert
        if (recipientId != sender.uid) {
          await NotificationsHelper.sendGeneralNotification(
            userId: recipientId,
            title: "Identity Transmission",
            body: "${sender.displayName ?? 'A peer'} sent you a message",
            data: {
              "route": "/messages",
              "threadId": convoId,
            },
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

  /// Marks a transmission as verified/read.
  ///
  /// Firestore rules permit this only for allowed users; failures are swallowed.
  static Future<void> markAsRead(String messageId) async {
    try {
      await _db
          .collection('messages')
          .doc(messageId)
          .update(<String, Object?>{'read': true});
    } catch (_) {
      // Silently fail if rules restrict updates or doc is missing.
    }
  }

  /// Purges a transmission from the secure ledger.
  ///
  /// Rules allow delete only for the sender (see firestore.rules).
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

  /// Real-time stream of incoming transmissions for [uid].
  ///
  /// Indexed by:
  /// - recipientId ASC
  /// - status ASC
  /// - timestamp DESC
  static Stream<QuerySnapshot<Map<String, dynamic>>> inboxStream(String uid) {
    return _db
        .collection('messages')
        .where('recipientId', isEqualTo: uid)
        .where('status', isEqualTo: 'sent')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Real-time stream of outbound transmissions for [uid].
  ///
  /// Indexed by:
  /// - senderId ASC
  /// - status ASC
  /// - timestamp DESC
  static Stream<QuerySnapshot<Map<String, dynamic>>> outboxStream(String uid) {
    return _db
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'sent')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Real-time stream of drafts authored by [uid].
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

  /// Generates a deterministic conversation ID for a pair of UIDs.
  static String _generateConvoId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }
}
