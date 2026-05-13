// lib/services/devotional_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Devotional Architecture — World-Class Manna Engine for SDA Youth.
/// Manages daily insights, verified community reflections, and personal archives.
class DevotionalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRIVATE UTILITIES ---

  /// Internal helper to fetch verified user metadata for the reflection stamp.
  static Future<Map<String, String>> _getVerifiedMetadata(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return {
        'name': (data['name'] ?? 'Mission Member').toString(),
        'photo': (data['photoURL'] ?? '').toString(),
      };
    } catch (e) {
      return {'name': 'Mission Member', 'photo': ''};
    }
  }

  // --- CONTENT BROADCAST (Admin Only) ---

  /// Broadcasts a new Manna insight to the community.
  static Future<DocumentReference<Map<String, dynamic>>?> broadcastManna({
    required String title,
    required String verse,
    required String message,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final ref = await _db.collection('devotionals').add({
        'title': title,
        'verse': verse,
        'message': message,
        'timestamp': now,
        'date': now, // Used for chronological sorting
        'readCount': 0,
      });
      return ref;
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st, reason: 'Manna broadcast failed');
      return null;
    }
  }

  // --- INTERACTION ENGINE ---

  /// Appends a verified reflection to a devotional.
  static Future<void> transmitReflection({
    required String devotionalId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.isEmpty) return;

    try {
      final meta = await _getVerifiedMetadata(user.uid);
      await _db.collection('devotionals').doc(devotionalId).collection('reflections').add({
        'userId': user.uid,
        'userName': meta['name'],
        'userPhoto': meta['photo'],
        'reflection': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Toggles a devotional in the user's personal "Sacred Archive".
  static Future<void> toggleFavorite(String devotionalId, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Aligned with firestore.rules: match /favorites/{favId}
    final favId = "${user.uid}_$devotionalId";
    final ref = _db.collection('favorites').doc(favId);

    try {
      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
      } else {
        await ref.set({
          'userId': user.uid,
          'itemId': devotionalId,
          'itemTitle': title,
          'itemType': 'devotional',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // --- PROGRESS TRACKING ---

  /// Marks a devotional as "Digested" (Read).
  static Future<void> markAsRead(String devotionalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('devotionals').doc(devotionalId).update({
        'readCount': FieldValue.increment(1)
      });
      // Optionally track per-user reading history here in future Phase
    } catch (_) {}
  }

  // --- DATA STREAMS ---

  /// Stream of all community Manna, ordered by latest date.
  static Stream<QuerySnapshot<Map<String, dynamic>>> mannaStream() {
    return _db.collection('devotionals')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots();
  }

  /// Stream to check if a specific devotional is favorited by the current user.
  static Stream<bool> isFavoritedStream(String devotionalId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return _db.collection('favorites')
        .doc("${user.uid}_$devotionalId")
        .snapshots()
        .map((doc) => doc.exists);
  }
}
