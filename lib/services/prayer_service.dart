// lib/services/prayer_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sda_youth_app/notifications_helper.dart';

/// Prayer Architecture — World-Class Intercession Engine for SDA Youth.
/// Manages community petitions, atomic Amen pulses, and verified spiritual metadata.
class PrayerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PRIVATE UTILITIES ---

  /// Internal helper to fetch verified user metadata for the prayer stamp.
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

  // --- TRANSMISSION ENGINE ---

  /// Broadcasts a new prayer petition to the community wall.
  static Future<DocumentReference<Map<String, dynamic>>?> transmitPetition({
    required String text,
    required String category,
    required bool isAnonymous,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final meta = await _getVerifiedMetadata(user.uid);
      final now = FieldValue.serverTimestamp();

      final ref = await _db.collection('prayer_requests').add({
        'userId': user.uid,
        'userName': isAnonymous ? 'Anonymous' : meta['name'],
        'userPhoto': isAnonymous ? null : meta['photo'],
        'request': text,
        'category': category,
        'isAnonymous': isAnonymous,
        'timestamp': now,
        'supportCount': 0, // The "Amen" counter
      });

      return ref;
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st, reason: 'Prayer transmission failed');
      return null;
    }
  }

  // --- INTERACTION LOGIC ---

  /// Sends an "Amen" signal. Increments the counter and notifies the petitioner.
  static Future<void> pulseAmen(String prayerId, String petitionerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final prayerRef = _db.collection('prayer_requests').doc(prayerId);
      
      // 1. Atomic counter update
      await prayerRef.update({'supportCount': FieldValue.increment(1)});

      // 2. Fetch my verified name for the notification
      final myMeta = await _getVerifiedMetadata(user.uid);

      // 3. Transmit spiritual support notification
      if (petitionerId != user.uid) {
        await NotificationsHelper.sendGeneralNotification(
          userId: petitionerId,
          title: "COMMUNITY AMEN",
          body: "${myMeta['name']} joined you in prayer.",
          data: {"route": "/prayer", "prayerId": prayerId},
        );
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Removes a petition from the wall. Author-only action.
  static Future<void> purgePetition(String prayerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ref = _db.collection('prayer_requests').doc(prayerId);
      final snap = await ref.get();
      
      if (snap.exists && snap.data()?['userId'] == user.uid) {
        await ref.delete();
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // --- DATA STREAMS ---

  /// Stream of all community petitions, ordered by latest first.
  static Stream<QuerySnapshot<Map<String, dynamic>>> petitionsStream({String? category}) {
    Query<Map<String, dynamic>> query = _db.collection('prayer_requests');
    
    if (category != null && category != 'General') {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.orderBy('timestamp', descending: true).limit(30).snapshots();
  }

  /// Stream of petitions created only by the current identity.
  static Stream<QuerySnapshot<Map<String, dynamic>>> myPetitionsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('prayer_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
