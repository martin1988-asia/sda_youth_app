// lib/notifications_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Transmission Hub — World-Class Notification & Alert Orchestrator.
/// Manages local haptic reminders and real-time community ledger alerts.
class NotificationsHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // ---------------------------------------------------------------------------
  // 1. LOCAL HAPTIC ENGINE (Mobile Only)
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        FirebaseAnalytics.instance.logEvent(
          name: "alert_interaction",
          parameters: {"payload": response.payload ?? "none"},
        );
      },
    );

    _isInitialized = true;
  }

  /// Transmits a high-priority daily scripture alert.
  static Future<void> transmitDailyManna(String verse) async {
    if (kIsWeb || !_isInitialized) return;
    try {
      await _plugin.show(
        id: 0,
        title: "DAILY MANNA",
        body: verse,
        notificationDetails: _missionChannelDetails(),
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: "Manna Transmission Failure",
      );
    }
  }

  /// Schedules a recurring spiritual reminder.
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (kIsWeb || !_isInitialized) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: 2,
        title: "SPIRITUAL FOCUS",
        body: "It's time for your daily devotional mission.",
        scheduledDate: scheduled,
        notificationDetails: _missionChannelDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: "Reminder Schedule Failure",
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (kIsWeb || !_isInitialized) return;
    await _plugin.cancelAll();
  }

  static Future<List<PendingNotificationRequest>> listPendingNotifications()
      async {
    if (kIsWeb || !_isInitialized) return <PendingNotificationRequest>[];
    return _plugin.pendingNotificationRequests();
  }

  static Future<void> cancelScheduledReminder() async {
    if (kIsWeb || !_isInitialized) return;
    await _plugin.cancel(id: 2);
  }

  static NotificationDetails _missionChannelDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'mission_alerts',
        'Mission Alerts',
        channelDescription: 'Official SDA Youth community transmissions',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF008080),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. COMMUNITY LEDGER ENGINE (Firestore)
  // ---------------------------------------------------------------------------

  /// Dispatches an in-app notification to a specific user.
  ///
  /// Writes to: /users/{userId}/notifications/{notifId}
  /// Adds:
  ///   - userId   (for collection group queries)
  ///   - timestamp
  ///   - read: false
  static Future<void> _dispatch(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        ...data,
      });

      await FirebaseAnalytics.instance.logEvent(
        name: "ledger_dispatch",
        parameters: {
          "type": data['type']?.toString() ?? 'unknown',
          "target": userId,
        },
      );
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  /// Transmits a Peer Connection request.
  static Future<void> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    await _dispatch(toUserId, {
      "type": "friend_request",
      "title": "CONNECTION REQUEST",
      "body": "$fromUserName wants to align with your mission.",
      "fromUserId": fromUserId,
      "data": {"route": "/friends"},
    });
  }

  /// Transmits a Reaction (Amen) alert.
  static Future<void> sendReactionNotification({
    required String postOwnerId,
    required String reactorId,
    required String reactorName,
    required String postId,
    required String reaction,
  }) async {
    await _dispatch(postOwnerId, {
      "type": "reaction",
      "title": "COMMUNITY AMEN",
      "body": "$reactorName said Amen to your post.",
      "fromUserId": reactorId,
      "data": {"route": "/home", "postId": postId},
    });
  }

  /// Transmits a Discussion (Comment) alert.
  static Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    required String postId,
    required String commentText,
  }) async {
    await _dispatch(postOwnerId, {
      "type": "comment",
      "title": "NEW INSIGHT",
      "body": "$commenterName shared an insight: '$commentText'",
      "fromUserId": commenterId,
      "data": {"route": "/home", "postId": postId},
    });
  }

  /// Transmits a General Identity or Mission alert.
  static Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _dispatch(userId, {
      "type": "general",
      "title": title.toUpperCase(),
      "body": body,
      "data": data,
    });
  }

  /// Notifies a user of a new post from a friend.
  static Future<void> sendPostNotification({
    required String toUserId,
    required String fromUserId,
    required String postId,
  }) async {
    await _dispatch(toUserId, {
      "type": "post",
      "title": "NEW TRANSMISSION",
      "body": "A peer shared a new mission update.",
      "fromUserId": fromUserId,
      "data": {"route": "/home", "postId": postId},
    });
  }

  /// Notifies an admin about content requiring moderation.
  static Future<void> sendModerationNotification({
    required String toAdminId,
    required String fromUserId,
    required String postId,
  }) async {
    await _dispatch(toAdminId, {
      "type": "moderation",
      "title": "SECURITY ALERT",
      "body": "New content requires administrative review.",
      "fromUserId": fromUserId,
      "data": {"route": "/moderation", "postId": postId},
    });
  }
}
