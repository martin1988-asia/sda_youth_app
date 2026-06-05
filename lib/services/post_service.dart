import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'notification_service.dart';
import 'moderation_service.dart';

class PostService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* =====================================================
     ⚖️ CONFIGURABLE WEIGHTS (FIXED ✅)
  ===================================================== */

  static const int likeWeight = 2;
  static const int commentWeight = 3;
  static const int shareWeight = 4;
  static const int saveWeight = 5;
  static const int viewWeight = 1;
  static const int faithBonus = 2;

  /* =====================================================
     ✝️ CONTENT FILTERING
  ===================================================== */

  static const List<String> _blockedWords = [
    "hate",
    "violence",
    "nsfw",
    "abuse",
  ];

  static const List<String> _faithKeywords = [
    "jesus",
    "god",
    "bible",
    "prayer",
    "faith",
    "blessing",
    "scripture",
    "amen",
  ];

  static bool isContentAllowed(String text) {
    final lower = text.toLowerCase();

    for (final word in _blockedWords) {
      if (lower.contains(word)) return false;
    }

    return true;
  }

  static bool isFaithContent(String text) {
    final lower = text.toLowerCase();

    for (final word in _faithKeywords) {
      if (lower.contains(word)) return true;
    }

    return false;
  }

  /* =====================================================
     🤖 AI HOOKS
  ===================================================== */

  static Future<bool> runModerationCheck(String text) async {
    return isContentAllowed(text);
  }

  static String classifyContent(String text) {
    if (isFaithContent(text)) return "faith";
    return "general";
  }

  /* =====================================================
     ✅ USER NAME
  ===================================================== */

  static Future<String> _getUserName(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      final data = doc.data();

      return (data?['name'] ?? 'User').toString();
    } catch (_) {
      return 'User';
    }
  }

  /* =====================================================
     🔥 POSTS STREAM
  ===================================================== */

  static Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() {
    return _db
        .collection('community_posts')
        .orderBy('score', descending: true)
        .limit(50)
        .snapshots();
  }

  /* =====================================================
     ❤️ LIKE SYSTEM
  ===================================================== */

  static Future<void> toggleLikeOnPost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = _db.collection('community_posts').doc(postId);

    final likeRef = postRef.collection('likes').doc(user.uid);

    try {
      final doc = await likeRef.get();
      final batch = _db.batch();

      if (doc.exists) {
        batch.delete(likeRef);

        batch.update(postRef, {
          'likeCount': FieldValue.increment(-1),
          'score': FieldValue.increment(-likeWeight),
        });
      } else {
        batch.set(likeRef, {
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        batch.update(postRef, {
          'likeCount': FieldValue.increment(1),
          'score': FieldValue.increment(likeWeight),
        });

        _triggerLikeNotification(postRef, user.uid);
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Like error: $e");
    }
  }

  /* =====================================================
     👁 VIEW
  ===================================================== */

  static Future<void> registerView(String postId) async {
    try {
      final postRef = _db.collection('community_posts').doc(postId);

      await postRef.update({
        'viewCount': FieldValue.increment(1),
        'score': FieldValue.increment(viewWeight),
      });
    } catch (e) {
      debugPrint("View error: $e");
    }
  }

  /* =====================================================
     💾 SAVE
  ===================================================== */

  static Future<void> savePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    try {
      await userRef.collection('saved_posts').doc(postId).set({
        'savedAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('community_posts').doc(postId).update({
        'saveCount': FieldValue.increment(1),
        'score': FieldValue.increment(saveWeight),
      });
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  /* =====================================================
     💬 COMMENT
  ===================================================== */

  static Future<void> addCommentToPost({
    required String postId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await ModerationService.moderate(text);

    if (result.isBlocked) {
      debugPrint(result.message);
      return;
    }

    if (result.shouldWarn) {
      debugPrint(result.message);
    }

    final postRef = _db.collection('community_posts').doc(postId);

    try {
      final name = await _getUserName(user.uid);

      await postRef.collection('comments').add({
        'userId': user.uid,
        'userName': name,
        'comment': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await postRef.update({
        'commentCount': FieldValue.increment(1),
        'score': FieldValue.increment(commentWeight),
      });

      final snap = await postRef.get();
      final data = snap.data();

      final ownerId = data?['authorId'];

      if (ownerId != null && ownerId != user.uid) {
        NotificationService.notifyComment(
          ownerUid: ownerId,
          postId: postId,
          commenterName: name,
          text: text,
        );
      }
    } catch (e) {
      debugPrint("Comment error: $e");
    }
  }

  /* =====================================================
     🔁 SHARE
  ===================================================== */

  static Future<void> registerShare(String postId) async {
    try {
      final postRef = _db.collection('community_posts').doc(postId);

      await postRef.update({
        'shareCount': FieldValue.increment(1),
        'score': FieldValue.increment(shareWeight),
      });
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  /* =====================================================
     🚨 REPORT
  ===================================================== */

  static Future<void> reportPost(String postId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('reports').add({
        'postId': postId,
        'reportedBy': user.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Report error: $e");
    }
  }

  /* =====================================================
     🙈 HIDE POST
  ===================================================== */

  static Future<void> hidePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('hidden_posts')
          .doc(postId)
          .set({'hiddenAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint("Hide error: $e");
    }
  }

  /* =====================================================
     🗑 DELETE
  ===================================================== */

  static Future<void> purgePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _db.collection('community_posts').doc(postId);

    try {
      final snap = await ref.get();
      final data = snap.data();

      if (data == null) return;
      if (data['authorId'] != user.uid) return;

      await ref.delete();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  /* =====================================================
     🔔 NOTIFICATIONS (FIXED ✅)
  ===================================================== */

  static Future<void> _triggerLikeNotification(
    DocumentReference<Map<String, dynamic>> postRef,
    String uid,
  ) async {
    try {
      final name = await _getUserName(uid);
      final snap = await postRef.get();

      final data = snap.data();
      final owner = data?['authorId'];

      if (owner != null && owner != uid) {
        NotificationService.notifyReaction(
          ownerUid: owner,
          postId: postRef.id,
          reactorName: name,
        );
      }
    } catch (e) {
      debugPrint("Notif error: $e");
    }
  }

  /* =====================================================
     📡 COMMENTS STREAM
  ===================================================== */

  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(
    String postId,
  ) {
    return _db
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /* =====================================================
   🔥 SMART FEED (NEW)
===================================================== */

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  smartFeedStream(String userId) async* {
    final postsSnap = await _db.collection('community_posts').limit(50).get();

    final followSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();

    final followingIds = followSnap.docs.map((d) => d.id).toSet();

    final posts = postsSnap.docs;

    // ✅ SORT manually using smart logic
    posts.sort((a, b) {
      final scoreA = _computeSmartScore(a.data(), followingIds);
      final scoreB = _computeSmartScore(b.data(), followingIds);

      return scoreB.compareTo(scoreA);
    });

    yield posts;
  }

  /* =====================================================
   🧠 SMART SCORE CALCULATION
===================================================== */

  static double _computeSmartScore(
    Map<String, dynamic> data,
    Set<String> followingIds,
  ) {
    double score = (data['score'] ?? 0).toDouble();

    final authorId = data['authorId'];
    final content = (data['content'] ?? "").toString();

    /// ✅ FOLLOW BOOST
    if (followingIds.contains(authorId)) {
      score += 10;
    }

    /// ✅ FAITH BOOST
    if (isFaithContent(content)) {
      score += 5;
    }

    /// ✅ ENGAGEMENT BOOST
    final likes = data['likeCount'] ?? 0;
    final comments = data['commentCount'] ?? 0;

    score += (likes * 0.3 + comments * 0.5);

    /// ✅ RECENCY BOOST
    final timestamp = data['timestamp'];

    if (timestamp is Timestamp) {
      final ageHours = DateTime.now().difference(timestamp.toDate()).inHours;

      score -= ageHours * 0.2; // decay
    }

    return score;
  }

  /* =====================================================
   🎬 SMART REELS FEED
===================================================== */

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  smartReelsStream(String userId) async* {
    final postsSnap = await _db.collection('community_posts').limit(50).get();

    final followSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();

    final followingIds = followSnap.docs.map((d) => d.id).toSet();

    final posts = postsSnap.docs;

    // ✅ Aggressive ranking for reels
    posts.sort((a, b) {
      final scoreA = _computeReelsScore(a.data(), followingIds);
      final scoreB = _computeReelsScore(b.data(), followingIds);

      return scoreB.compareTo(scoreA);
    });

    yield posts;
  }

  /* =====================================================
   🎬 REELS SCORE ENGINE
===================================================== */

  static double _computeReelsScore(
    Map<String, dynamic> data,
    Set<String> followingIds,
  ) {
    double score = (data['score'] ?? 0).toDouble();

    final authorId = data['authorId'];
    final content = (data['content'] ?? "").toString();

    /// ✅ STRONG FOLLOW BOOST (more aggressive than feed)
    if (followingIds.contains(authorId)) {
      score += 15;
    }

    /// ✅ STRONG FAITH BOOST
    if (isFaithContent(content)) {
      score += 10;
    }

    /// ✅ ENGAGEMENT BOOST (heavier than feed)
    final likes = data['likeCount'] ?? 0;
    final comments = data['commentCount'] ?? 0;
    final shares = data['shareCount'] ?? 0;

    score += (likes * 0.5 + comments * 0.8 + shares * 1.2);

    /// ✅ VIRAL BOOST
    if (likes > 30 || comments > 10) {
      score += 20;
    }

    /// ✅ RECENCY (less decay so viral content lives longer)
    final timestamp = data['timestamp'];

    if (timestamp is Timestamp) {
      final ageHours = DateTime.now().difference(timestamp.toDate()).inHours;

      score -= ageHours * 0.1;
    }

    return score;
  }
}
