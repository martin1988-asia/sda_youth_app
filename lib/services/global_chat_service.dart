import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// ✅ GLOBAL CHAT SERVICE (STABLE + FULL FEATURE)
class GlobalChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =====================================================
  // ✅ USER METADATA
  // =====================================================

  static Future<Map<String, String>> _getUserMeta(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      return {
        'name': (data['name'] ?? 'User').toString(),
        'photo': (data['profileImageUrl'] ?? '').toString(),
      };
    } catch (_) {
      return {'name': 'User', 'photo': ''};
    }
  }

  // =====================================================
  // ✅ SEND MESSAGE
  // =====================================================

  static Future<void> sendMessage(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.trim().isEmpty) return;

    try {
      final meta = await _getUserMeta(user.uid);

      await _db.collection('global_chat').add({
        'senderId': user.uid,
        'senderName': meta['name'],
        'senderPhoto': meta['photo'],
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user.uid],
        'edited': false,
      });
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st);
      }
    }
  }

  // =====================================================
  // ✅ EDIT MESSAGE
  // =====================================================

  static Future<void> editMessage(String messageId, String newText) async {
    try {
      await _db.collection('global_chat').doc(messageId).update({
        'text': newText.trim(),
        'edited': true,
      });
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st);
      }
    }
  }

  // =====================================================
  // ✅ DELETE MESSAGE
  // =====================================================

  static Future<void> deleteMessage(String messageId) async {
    try {
      await _db.collection('global_chat').doc(messageId).delete();
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(e, st);
      }
    }
  }

  // =====================================================
  // ✅ STREAM MESSAGES
  // =====================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages() {
    return _db
        .collection('global_chat')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // =====================================================
  // ✅ READ RECEIPTS
  // =====================================================

  static Future<void> markAsRead(String messageId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('global_chat').doc(messageId).update({
        'readBy': FieldValue.arrayUnion([uid]),
      });
    } catch (_) {}
  }

  // =====================================================
  // ✅ TYPING INDICATOR
  // =====================================================

  static Future<void> setTyping(bool isTyping) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('typing').doc(uid).set({
        'typing': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> typingStream() {
    return _db.collection('typing').snapshots();
  }

  // =====================================================
  // ✅ ONLINE PRESENCE
  // =====================================================

  static Future<void> setOnline(bool online) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('presence').doc(uid).set({
        'online': online,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> presenceStream() {
    return _db.collection('presence').snapshots();
  }
}
