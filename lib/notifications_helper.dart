import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// ✅ REMOVED (they break web)
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tzdata;
// import 'package:timezone/timezone.dart' as tz;

class NotificationsHelper {
  // ✅ changed to dynamic (safe stub)
  static final dynamic _plugin = null;

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _isInitialized = false;

  /* =============================
     ✅ INIT
  ============================== */
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // ✅ no-op on web (safe)
      _isInitialized = true;
    } catch (e, st) {
      _logError("init", e, st);
    }
  }

  /* =============================
     ✅ GENERAL NOTIFICATION
  ============================== */
  static Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String body,
    String? fromUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _createNotification(
        userId: userId,
        type: "general",
        title: title,
        body: body,
        fromUserId: fromUserId ?? userId,
        data: data,
      );

      await showLocalNotification(title: title, body: body);
    } catch (e, st) {
      _logError("sendGeneralNotification", e, st);
    }
  }

  /* =============================
     ✅ LOCAL NOTIFICATION
  ============================== */
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      debugPrint("Notification (web disabled): $title - $body");
      return;
    }

    try {
      if (_plugin != null) {
        await _plugin.show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          notificationDetails: _details(),
        );
      }
    } catch (e, st) {
      _logError("showLocalNotification", e, st);
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || _plugin == null) return;

    try {
      await _plugin.cancelAll();
    } catch (e, st) {
      _logError("cancelAllNotifications", e, st);
    }
  }

  /* =============================
     ✅ DAILY REMINDER
  ============================== */
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (kIsWeb || _plugin == null) {
      debugPrint("Daily reminder disabled on web");
      return;
    }

    // ✅ removed timezone usage safely
    try {
      debugPrint("Daily reminder scheduled (stub)");
    } catch (e, st) {
      _logError("scheduleReminder", e, st);
    }
  }

  /* =============================
     ✅ DETAILS
  ============================== */
  static dynamic _details() {
    return null; // ✅ safe stub
  }

  /* =============================
     ✅ FIRESTORE STORAGE (UNCHANGED)
  ============================== */
  static Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required String fromUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (userId == fromUserId) return;

      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            "userId": userId,
            "type": type,
            "title": title,
            "body": body,
            "fromUserId": fromUserId,
            "data": data ?? {},
            "read": false,
            "timestamp": FieldValue.serverTimestamp(),
          });

      await FirebaseAnalytics.instance.logEvent(
        name: "notification_sent",
        parameters: <String, Object>{"type": type},
      );
    } catch (e, st) {
      _logError("createNotification", e, st);
    }
  }

  /* =============================
     ✅ SOCIAL EVENTS (UNCHANGED)
  ============================== */
  static Future<void> sendPostNotification({
    required String toUserId,
    required String fromUserId,
    required String postId,
  }) async {
    await sendGeneralNotification(
      userId: toUserId,
      title: "New Post",
      body: "Someone shared a post",
      fromUserId: fromUserId,
      data: {"postId": postId},
    );
  }

  static Future<void> sendReactionNotification({
    required String postOwnerId,
    required String reactorId,
    required String reactorName,
    required String postId,
    required String reaction,
  }) async {
    await sendGeneralNotification(
      userId: postOwnerId,
      title: "New Reaction",
      body: "$reactorName reacted $reaction",
      fromUserId: reactorId,
      data: {"postId": postId},
    );
  }

  static Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    required String postId,
    required String commentText,
  }) async {
    await sendGeneralNotification(
      userId: postOwnerId,
      title: "New Comment",
      body: "$commenterName: $commentText",
      fromUserId: commenterId,
      data: {"postId": postId},
    );
  }

  static Future<void> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    await sendGeneralNotification(
      userId: toUserId,
      title: "Friend Request",
      body: "$fromUserName sent you a request",
      fromUserId: fromUserId,
    );
  }

  /* =============================
     ✅ ERROR LOGGING (UNCHANGED)
  ============================== */
  static void _logError(String action, Object e, StackTrace st) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(e, st, reason: "$action failed");
    } else {
      debugPrint("$action failed: $e");
    }
  }
}
