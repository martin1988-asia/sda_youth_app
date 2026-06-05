// lib/services/security_queue_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'admin_service.dart';

/// SecurityQueueService — Centralized moderation queue management.
/// Provides enqueueing, streaming, resolving, banning, dismissing, and audit logging.
class SecurityQueueService {
  static final _queueRef = FirebaseFirestore.instance.collection('moderation');
  static final _logsRef = FirebaseFirestore.instance.collection('securityLogs');

  /// Stream all incidents in the queue, ordered by timestamp.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamQueue() {
    return _queueRef.orderBy('timestamp', descending: true).snapshots();
  }

  /// Add a new incident to the queue.
  static Future<void> enqueueIncident({
    required String userId,
    required String reason,
    required String type,
    String severity = 'medium',
  }) async {
    try {
      await _queueRef.add({
        'userId': userId,
        'reason': reason,
        'type': type,
        'severity': severity,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      await FirebaseAnalytics.instance.logEvent(
        name: 'incident_enqueued',
        parameters: {'userId': userId, 'type': type, 'severity': severity},
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      rethrow;
    }
  }

  /// Dismiss an incident (remove from queue).
  static Future<void> dismissIncident(
    String moderationId,
    String userId,
  ) async {
    try {
      await _queueRef.doc(moderationId).delete();
      await _logAction('dismiss', moderationId, userId);
      await FirebaseAnalytics.instance.logEvent(
        name: 'incident_dismissed',
        parameters: {'target_identity': userId},
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      rethrow;
    }
  }

  /// Ban a user and remove incident from queue.
  static Future<void> banUserAndRemove({
    required String moderationId,
    required String userId,
  }) async {
    try {
      await AdminService.terminateUserIdentity(userId);
      await _queueRef.doc(moderationId).delete();
      await _logAction('ban', moderationId, userId);
      await FirebaseAnalytics.instance.logEvent(
        name: 'incident_banned',
        parameters: {'target_identity': userId},
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      rethrow;
    }
  }

  /// Mark incident as resolved without deletion.
  static Future<void> resolveIncident(
    String moderationId,
    String userId,
  ) async {
    try {
      await _queueRef.doc(moderationId).update({'status': 'resolved'});
      await _logAction('resolve', moderationId, userId);
      await FirebaseAnalytics.instance.logEvent(
        name: 'incident_resolved',
        parameters: {'target_identity': userId},
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      rethrow;
    }
  }

  /// Internal helper to log actions into audit trail.
  static Future<void> _logAction(
    String action,
    String moderationId,
    String userId,
  ) async {
    await _logsRef.add({
      'action': action,
      'moderationId': moderationId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
