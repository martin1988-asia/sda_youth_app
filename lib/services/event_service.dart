// lib/services/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Event Architecture — World-Class Gathering Engine for SDA Youth.
/// Manages mission coordination, verified RSVPs, and community milestones.
class EventService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRIVATE UTILITIES ---

  /// Internal helper to fetch verified user metadata for the event stamp.
  static Future<Map<String, String>> _getVerifiedMetadata(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return {
        'name': (data['name'] ?? 'Mission Leader').toString(),
        'photo': (data['photoURL'] ?? '').toString(),
      };
    } catch (e) {
      return {'name': 'Mission Leader', 'photo': ''};
    }
  }

  // --- MISSION COORDINATION ---

  /// Broadcasts a new mission gathering to the community.
  static Future<DocumentReference<Map<String, dynamic>>?> broadcastEvent({
    required String title,
    required String details,
    required DateTime date,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final meta = await _getVerifiedMetadata(user.uid);
      final now = FieldValue.serverTimestamp();

      final ref = await _db.collection('events').add({
        'title': title,
        'details': details,
        'date': Timestamp.fromDate(date),
        'organizerId': user.uid,
        'organizerName': meta['name'],
        'organizerPhoto': meta['photo'],
        'timestamp': now,
        'participantCount': 0,
      });

      return ref;
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st, reason: 'Event broadcast failed');
      return null;
    }
  }

  // --- RSVP ENGINE ---

  /// Joins or Leaves a mission. Updates the atomic participant ledger.
  static Future<void> toggleRsvp(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final eventRef = _db.collection('events').doc(eventId);
    final participantRef = eventRef.collection('participants').doc(user.uid);

    try {
      final existing = await participantRef.get();

      if (existing.exists) {
        // Leave Mission
        final batch = _db.batch();
        batch.delete(participantRef);
        batch.update(eventRef, {'participantCount': FieldValue.increment(-1)});
        await batch.commit();
      } else {
        // Join Mission
        final meta = await _getVerifiedMetadata(user.uid);
        final batch = _db.batch();
        batch.set(participantRef, {
          'userId': user.uid,
          'userName': meta['name'],
          'userPhoto': meta['photo'],
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.update(eventRef, {'participantCount': FieldValue.increment(1)});
        await batch.commit();
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Removes an event from the hub. Organizer-only action.
  static Future<void> purgeEvent(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ref = _db.collection('events').doc(eventId);
      final snap = await ref.get();
      if (snap.exists && snap.data()?['organizerId'] == user.uid) {
        await ref.delete();
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // --- DATA STREAMS ---

  /// Stream of upcoming missions, ordered by mission date (closest first).
  static Stream<QuerySnapshot<Map<String, dynamic>>> upcomingMissionsStream() {
    return _db.collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date', descending: false)
        .snapshots();
  }

  /// Checks if the current identity is signed up for a specific mission.
  static Stream<bool> isAttendingStream(String eventId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return _db.collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
