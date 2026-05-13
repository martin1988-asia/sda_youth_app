// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Admin Architecture — Sovereign Command & Analytics Engine for SDA Youth.
/// Manages global community metrics, content purges, and identity termination.
class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // GLOBAL ANALYTICS (MISSION INTELLIGENCE)
  // ---------------------------------------------------------------------------

  /// Fetches a high-fidelity snapshot of the community health and growth.
  static Future<Map<String, dynamic>> getKingdomSnapshot() async {
    try {
      final members = await _db.collection('users').count().get();
      final posts = await _db.collection('community_posts').count().get();
      final prayers = await _db.collection('prayer_requests').count().get();
      final testimonies = await _db.collection('testimonies').count().get();
      
      // Calculate Velocity: New members in the last 7 days
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final newMembers = await _db.collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .count().get();

      return {
        'totalMembers': members.count ?? 0,
        'newMembersThisWeek': newMembers.count ?? 0,
        'totalPosts': posts.count ?? 0,
        'activePrayers': prayers.count ?? 0,
        'totalTestimonies': testimonies.count ?? 0,
        'healthStatus': (members.count ?? 0) > 0 ? 'ACTIVE' : 'STAGNANT',
      };
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      return {};
    }
  }

  /// Fetches the top 5 Ambassadors (highest XP) for leadership review.
  static Future<List<Map<String, dynamic>>> getTopAmbassadors() async {
    try {
      final snap = await _db.collection('users')
          .orderBy('xp', descending: true)
          .limit(5)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Original global metrics for backward compatibility with the Dashboard.
  static Future<Map<String, int>> getGlobalMetrics() async {
    try {
      final members = await _db.collection('users').count().get();
      final posts = await _db.collection('community_posts').count().get();
      final events = await _db.collection('events').count().get();
      final prayers = await _db.collection('prayer_requests').count().get();
      final testimonies = await _db.collection('testimonies').count().get();

      return {
        'totalMembers': members.count ?? 0,
        'totalPosts': posts.count ?? 0,
        'activeEvents': events.count ?? 0,
        'activePrayers': prayers.count ?? 0,
        'totalTestimonies': testimonies.count ?? 0,
      };
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // SOVEREIGN CONTENT GOVERNANCE (PURGE PROTOCOLS)
  // ---------------------------------------------------------------------------

  static Future<void> sovereignPostDelete(String postId) async {
    try {
      await _db.collection('community_posts').doc(postId).delete();
      _logAdminAction('post_delete', postId);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static Future<void> sovereignCommentDelete(String postId, String commentId) async {
    try {
      await _db.collection('community_posts').doc(postId).collection('comments').doc(commentId).delete();
      await _db.collection('community_posts').doc(postId).update({'commentCount': FieldValue.increment(-1)});
      _logAdminAction('comment_delete', commentId);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static Future<void> sovereignTestimonyDelete(String testimonyId) async {
    try {
      await _db.collection('testimonies').doc(testimonyId).delete();
      _logAdminAction('testimony_delete', testimonyId);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static Future<void> sovereignPrayerDelete(String prayerId) async {
    try {
      await _db.collection('prayer_requests').doc(prayerId).delete();
      _logAdminAction('prayer_delete', prayerId);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static Future<void> sovereignEventDelete(String eventId) async {
    try {
      await _db.collection('events').doc(eventId).delete();
      _logAdminAction('event_delete', eventId);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static Future<void> sovereignDevotionalDelete(String devotionalId) async {
    try {
      await _db.collection('devotionals').doc(devotionalId).delete();
      _logAdminAction('devotional_delete', devotionalId);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // IDENTITY GOVERNANCE (TERMINATE USERS)
  // ---------------------------------------------------------------------------

  static Future<void> terminateUserIdentity(String uid) async {
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid));
      batch.delete(_db.collection('user_lookup').doc(uid));
      await batch.commit();
      _logAdminAction('user_termination', uid);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  static Future<void> setMemberRole(String uid, String role) async {
    try {
      await _db.collection('users').doc(uid).update({'role': role});
      _logAdminAction('role_update', '$uid -> $role');
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE AUDIT ENGINE
  // ---------------------------------------------------------------------------

  static void _logAdminAction(String type, String targetId) {
    final admin = FirebaseAuth.instance.currentUser;
    _db.collection('admin_audit_logs').add({
      'adminUid': admin?.uid,
      'adminEmail': admin?.email,
      'actionType': type,
      'targetId': targetId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
