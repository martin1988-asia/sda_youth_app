// lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Gamification Architecture — World-Class Engagement Engine for SDA Youth.
/// Manages XP rewards, badge eligibility, and the Kingdom Honor ledger.
class GamificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- XP REWARD CONSTANTS ---
  static const int xpDevotionalRead = 10;
  static const int xpPrayerPosted = 15;
  static const int xpAmenGiven = 5;
  static const int xpLessonCompleted = 50;

  // ---------------------------------------------------------------------------
  // HONOR LEDGER ENGINE
  // ---------------------------------------------------------------------------

  /// Grants XP to a user and updates their rank status.
  static Future<void> awardXp(int amount, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final int currentXp = snapshot.data()?['xp'] ?? 0;
        final int newXp = currentXp + amount;

        // Clean Rank Logic with proper block formatting
        String rank = "Seeker";
        if (newXp > 1000) {
          rank = "Ambassador";
        } else if (newXp > 500) {
          rank = "Disciple";
        } else if (newXp > 100) {
          rank = "Witness";
        }

        transaction.update(userRef, {
          'xp': newXp,
          'rank': rank,
          'lastXpGain': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // BADGE SYSTEM (Aligned with firestore.rules)
  // ---------------------------------------------------------------------------

  /// Awards a specific badge to the user's permanent collection.
  static Future<void> awardBadge({
    required String badgeId,
    required String title,
    required String iconUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final badgeRef = _db.collection('users')
        .doc(user.uid)
        .collection('badges')
        .doc(badgeId);

    try {
      await badgeRef.set({
        'badgeId': badgeId,
        'title': title,
        'iconUrl': iconUrl,
        'awardedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // DATA STREAMS
  // ---------------------------------------------------------------------------

  /// Stream of user's current XP and Rank directly from the identity ledger.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProgressStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
  }

  /// Stream of all awarded badges for the current identity.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyBadgesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users')
        .doc(user.uid)
        .collection('badges')
        .orderBy('awardedAt', descending: true)
        .snapshots();
  }
}
