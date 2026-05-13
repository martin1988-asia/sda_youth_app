// lib/services/global_chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Global Chat Architecture — High-fidelity Mass Communication Engine.
/// Manages the public community ledger and verified identity transmissions.
class GlobalChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // IDENTITY RESOLUTION
  // ---------------------------------------------------------------------------

  /// Fetches verified metadata for the sender stamp.
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

  // ---------------------------------------------------------------------------
  // TRANSMISSION ENGINE
  // ---------------------------------------------------------------------------

  /// Transmits a message to the Global Hub.
  static Future<void> transmitMessage(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.trim().isEmpty) return;

    try {
      final meta = await _getVerifiedMetadata(user.uid);
      
      await _db.collection('global_chat').add({
        'senderId': user.uid,
        'senderName': meta['name'],
        'senderPhoto': meta['photo'],
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Sovereign Purge: Deletes a specific transmission (Admin Only).
  static Future<void> purgeTransmission(String messageId) async {
    try {
      await _db.collection('global_chat').doc(messageId).delete();
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // DATA STREAMS
  // ---------------------------------------------------------------------------

  /// Real-time stream of the global community pulse.
  static Stream<QuerySnapshot<Map<String, dynamic>>> globalStream() {
    return _db.collection('global_chat')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }
}
