// lib/services/lesson_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Academy Architecture — World-Class Learning Engine for SDA Youth.
/// Manages course delivery, user enrollments, and academic progress tracking.
class LessonService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // COURSE RETRIEVAL
  // ---------------------------------------------------------------------------

  /// Streams the global course catalog from the /courses ledger.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getCourseCatalog() {
    return _db.collection('courses').orderBy('order').snapshots();
  }

  /// Fetches structured lessons for a specific course.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLessonsStream(String courseId) {
    return _db.collection('courses')
        .doc(courseId)
        .collection('lessons')
        .orderBy('order')
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // PROGRESS & ENROLLMENT (Aligned with firestore.rules)
  // ---------------------------------------------------------------------------

  /// Enrolls the current identity into a specific course.
  static Future<void> enrollInCourse(String courseId, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final enrollmentRef = _db.collection('users')
        .doc(user.uid)
        .collection('enrollments')
        .doc(courseId);

    try {
      await enrollmentRef.set({
        'courseId': courseId,
        'courseTitle': title,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0.0,
        'completed': false,
        'lastLessonId': null,
      }, SetOptions(merge: true));
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st, reason: 'Enrollment failed');
    }
  }

  /// Updates the user's progress within a course.
  static Future<void> updateProgress({
    required String courseId,
    required double progress,
    String? currentLessonId,
    bool finished = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(courseId)
          .update({
        'progress': progress,
        'lastLessonId': currentLessonId,
        'completed': finished,
        'lastAccessed': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Checks if the user is already enrolled in a course.
  static Stream<bool> checkEnrollment(String courseId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return _db.collection('users')
        .doc(user.uid)
        .collection('enrollments')
        .doc(courseId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
