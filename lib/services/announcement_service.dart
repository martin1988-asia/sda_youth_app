// lib/services/announcement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Announcement Architecture — World-Class Broadcast Engine for SDA Youth.
/// Manages global community updates, urgent alerts, and mission-critical info.
class AnnouncementService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // BROADCAST ENGINE (Admin Only)
  // ---------------------------------------------------------------------------

  /// Broadcasts a new announcement to the community ledger.
  static Future<DocumentReference<Map<String, dynamic>>?> broadcast({
    required String title,
    required String message,
    required String category, // 'Urgent', 'Update', 'Inspiration'
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final now = FieldValue.serverTimestamp();
      final ref = await _db.collection('announcements').add({
        'title': title,
        'message': message,
        'category': category,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Mission Control',
        'timestamp': now,
      });

      // Note: Full mass-push notification logic typically resides in Cloud Functions.
      // This client-side trigger ensures the record is finalized.
      return ref;
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st, reason: 'Broadcast failed');
      }
      return null;
    }
  }

  /// Purges a broadcast from the ledger. Sovereign control action.
  static Future<void> purgeBroadcast(String id) async {
    try {
      await _db.collection('announcements').doc(id).delete();
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // DATA STREAMS
  // ---------------------------------------------------------------------------

  /// Real-time stream of all community broadcasts, ordered by latest priority.
  static Stream<QuerySnapshot<Map<String, dynamic>>> announcementsStream() {
    return _db.collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
}
