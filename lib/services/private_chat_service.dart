import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivateChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =====================================================
  // ✅ HELPERS
  // =====================================================

  static String get currentUid => FirebaseAuth.instance.currentUser!.uid;

  static String _conversationKey(String a, String b) {
    final sorted = [a, b]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  // =====================================================
  // ✅ CREATE / GET CONVERSATION
  // =====================================================

  static Future<String> getOrCreateConversation(String targetUserId) async {
    final uid = currentUid;

    if (uid == targetUserId) return '';

    final key = _conversationKey(uid, targetUserId);

    final query = await _db
        .collection('conversations')
        .where('conversationKey', isEqualTo: key)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    final doc = await _db.collection('conversations').add({
      'participants': [uid, targetUserId],
      'conversationKey': key,
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {uid: 0, targetUserId: 0},
    });

    return doc.id;
  }

  // =====================================================
  // ✅ SEND MESSAGE (FIXED + NOTIFICATIONS ✅)
  // =====================================================

  static Future<void> sendMessage(String conversationId, String text) async {
    final uid = currentUid;

    if (text.trim().isEmpty) return;

    final convRef = _db.collection('conversations').doc(conversationId);

    final convSnap = await convRef.get();

    if (!convSnap.exists) return;

    final data = convSnap.data()!;
    final participants = List<String>.from(data['participants'] ?? []);

    if (participants.isEmpty) return;

    final receiver = participants.firstWhere((u) => u != uid, orElse: () => '');

    if (receiver.isEmpty) return;

    final trimmedText = text.trim();

    // ✅ SAVE MESSAGE
    await convRef.collection('messages').add({
      'senderId': uid,
      'text': trimmedText,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // ✅ UPDATE CONVERSATION
    await convRef.set({
      'lastMessage': trimmedText,
      'lastSender': uid,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {receiver: FieldValue.increment(1)},
    }, SetOptions(merge: true));

    // ✅ ✅ CREATE NOTIFICATION (FIX)
    try {
      await _db
          .collection('users')
          .doc(receiver)
          .collection('notifications')
          .add({
            'type': 'message',
            'fromUserId': uid,
            'text': trimmedText,
            'conversationId': conversationId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
    } catch (_) {
      // ✅ do not break message flow
    }
  }

  // =====================================================
  // ✅ STREAM MESSAGES
  // =====================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(
    String conversationId,
  ) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // =====================================================
  // ✅ INBOX STREAM
  // =====================================================

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  inboxStream() {
    final uid = currentUid;

    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;

          docs.sort((a, b) {
            final aTime = a.data()['lastTimestamp'] as Timestamp?;
            final bTime = b.data()['lastTimestamp'] as Timestamp?;

            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return docs;
        });
  }

  // =====================================================
  // ✅ MARK AS READ
  // =====================================================

  static Future<void> markAsRead(String conversationId) async {
    final uid = currentUid;

    final ref = _db.collection('conversations').doc(conversationId);

    final messages = await ref.collection('messages').get();

    final batch = _db.batch();

    for (final doc in messages.docs) {
      final data = doc.data();

      if (data['senderId'] != uid && data['read'] == false) {
        batch.update(doc.reference, {'read': true});
      }
    }

    batch.set(ref, {
      'unreadCount': {uid: 0},
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // =====================================================
  // ✅ TYPING INDICATOR
  // =====================================================

  static Future<void> setTyping(String conversationId, bool typing) async {
    final uid = currentUid;

    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .doc(uid)
        .set({'typing': typing, 'timestamp': FieldValue.serverTimestamp()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> typingStream(
    String conversationId,
  ) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots();
  }
}
