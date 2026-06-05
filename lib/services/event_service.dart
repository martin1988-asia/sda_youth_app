// lib/services/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Event Service — aligned with Firestore rules & indexes.
/// Manages event creation, RSVP participants, and event media.
class EventService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRIVATE UTILITIES ---

  static Future<Map<String, String>> _getVerifiedMetadata(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return {
        'name': (data['name'] ?? 'Anonymous').toString(),
        'photo': (data['photoURL'] ?? '').toString(),
      };
    } catch (e) {
      return {'name': 'Anonymous', 'photo': ''};
    }
  }

  // --- EVENT CREATION ---

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
        'createdAt': now,
        'participantCount': 0,
      });

      return ref;
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'broadcastEvent failed',
        );
      }
      return null;
    }
  }

  // --- RSVP PARTICIPANTS ---

  static Future<void> toggleRsvp(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final eventRef = _db.collection('events').doc(eventId);
    final participantRef = eventRef.collection('participants').doc(user.uid);

    try {
      final existing = await participantRef.get();

      if (existing.exists) {
        final batch = _db.batch();
        batch.delete(participantRef);
        batch.update(eventRef, {'participantCount': FieldValue.increment(-1)});
        await batch.commit();
      } else {
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
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'toggleRsvp failed',
        );
      }
    }
  }

  // --- EVENT MEDIA ---

  static Future<void> uploadEventMedia(
    String eventId,
    String mediaId,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('media')
          .doc(mediaId)
          .set({
            ...data,
            'uploadedBy': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'uploadEventMedia failed',
        );
      }
    }
  }

  // --- EVENT MANAGEMENT ---

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
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'purgeEvent failed',
        );
      }
    }
  }

  // --- UPCOMING MISSIONS STREAM ---

  static Stream<QuerySnapshot<Map<String, dynamic>>> upcomingMissionsStream() {
    final now = DateTime.now();
    return _db
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date')
        .snapshots();
  }

  // --- IS ATTENDING STREAM ---

  static Stream<bool> isAttendingStream(String eventId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    final participantRef = _db
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(user.uid);

    return participantRef.snapshots().map((doc) => doc.exists);
  }
}
