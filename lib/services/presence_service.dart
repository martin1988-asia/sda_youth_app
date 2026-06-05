import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<void> setOnline() async {
    try {
      await _db.collection('users').doc(_uid).set({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> setOffline() async {
    try {
      await _db.collection('users').doc(_uid).set({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
