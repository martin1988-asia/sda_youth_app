import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> follow(String targetId) async {
    final me = FirebaseAuth.instance.currentUser!;
    final myId = me.uid;

    await _db
        .collection('users')
        .doc(targetId)
        .collection('followers')
        .doc(myId)
        .set({});

    await _db
        .collection('users')
        .doc(myId)
        .collection('following')
        .doc(targetId)
        .set({});
  }

  static Future<void> unfollow(String targetId) async {
    final me = FirebaseAuth.instance.currentUser!;
    final myId = me.uid;

    await _db
        .collection('users')
        .doc(targetId)
        .collection('followers')
        .doc(myId)
        .delete();

    await _db
        .collection('users')
        .doc(myId)
        .collection('following')
        .doc(targetId)
        .delete();
  }

  static Stream<bool> isFollowing(String targetId) {
    final me = FirebaseAuth.instance.currentUser!;
    return _db
        .collection('users')
        .doc(targetId)
        .collection('followers')
        .doc(me.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
