import 'package:cloud_firestore/cloud_firestore.dart';

class FeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Get ranked feed (core engine)
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getRankedFeed(String userId) async {
    try {
      final snapshot = await _db
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final docs = snapshot.docs;

      // ✅ sort using score
      docs.sort((a, b) {
        final scoreA = _score(a);
        final scoreB = _score(b);
        return scoreB.compareTo(scoreA);
      });

      return docs;
    } catch (e) {
      return [];
    }
  }

  /// ✅ Ranking algorithm
  static double _score(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final int likes = (data['likes'] ?? 0) as int;
    final int comments = (data['comments'] ?? 0) as int;

    final Timestamp? ts = data['timestamp'];
    final int ageHours = ts != null
        ? DateTime.now().difference(ts.toDate()).inHours
        : 1;

    // ✅ engagement + freshness
    return (likes * 2.0 + comments * 3.0) - (ageHours * 0.1);
  }
}
