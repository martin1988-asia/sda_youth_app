// lib/services/bible_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Bible Architecture — World-Class Scripture Engine for SDA Youth.
/// Manages holy text retrieval, sacred markers (bookmarks), and search logic.
class BibleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // SCRIPTURE RETRIEVAL
  // ---------------------------------------------------------------------------

  /// Fetches all books for the selection hub.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getBooksStream() {
    return _db.collection('bible').orderBy('order').snapshots();
  }

  /// Fetches a specific chapter's verses.
  static Future<List<Map<String, dynamic>>> getChapterVerses(String bookId, int chapterNum) async {
    try {
      final snap = await _db
          .collection('bible')
          .doc(bookId)
          .collection('chapters')
          .doc(chapterNum.toString())
          .collection('verses')
          .orderBy('number')
          .get();

      return snap.docs.map((d) => d.data()).toList();
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st, reason: 'Bible fetch failed');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // SACRED MARKERS (BOOKMARKS & HIGHLIGHTS)
  // ---------------------------------------------------------------------------

  /// Toggles a "Sacred Marker" (Bookmark) on a specific verse.
  static Future<void> toggleSacredMarker({
    required String bookName,
    required int chapter,
    required int verse,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final markerId = "${user.uid}_${bookName}_${chapter}_$verse";
    final ref = _db.collection('favorites').doc(markerId);

    try {
      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
      } else {
        await ref.set({
          'userId': user.uid,
          'itemType': 'scripture',
          'book': bookName,
          'chapter': chapter,
          'verse': verse,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Stream of the current user's bookmarks for a specific chapter.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMarkersStream(String bookName, int chapter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('itemType', isEqualTo: 'scripture')
        .where('book', isEqualTo: bookName)
        .where('chapter', isEqualTo: chapter)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // SEARCH ENGINE
  // ---------------------------------------------------------------------------

  /// Simple keyword search across the community's localized bible collection.
  static Future<List<Map<String, dynamic>>> searchScripture(String query) async {
    // Note: Advanced search requires Algolia or a dedicated Indexing service.
    // This is a high-level Firestore placeholder.
    try {
      final snap = await _db.collectionGroup('verses')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();
      
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      return [];
    }
  }
}
