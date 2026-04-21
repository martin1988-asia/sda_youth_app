import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ---------------- LOCAL NOTIFICATIONS ----------------
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> scheduleDailyVerse(String verse) async {
    await _plugin.show(
      0,
      "Daily Verse",
      verse,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_verse_channel',
          'Daily Verse',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.show(
      1,
      "Daily Reminder",
      "It's time for your devotional!",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ---------------- FIRESTORE NOTIFICATIONS ----------------
  static Future<void> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .add({
      "title": "New Friend Request",
      "body": "$fromUserName sent you a friend request",
      "type": "friend_request",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "fromUserId": fromUserId,
    });
  }

  static Future<void> sendReactionNotification({
    required String postOwnerId,
    required String reactorId,
    required String reactorName,
    required String postId,
    required String reaction,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(postOwnerId)
        .collection('notifications')
        .add({
      "title": "New Reaction",
      "body": "$reactorName reacted $reaction to your post",
      "type": "reaction",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "postId": postId,
      "reaction": reaction,
      "fromUserId": reactorId,
    });
  }

  static Future<void> sendCommentNotification({
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    required String postId,
    required String commentText,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(postOwnerId)
        .collection('notifications')
        .add({
      "title": "New Comment",
      "body": "$commenterName commented: '$commentText'",
      "type": "comment",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "postId": postId,
      "fromUserId": commenterId,
    });
  }

  static Future<void> sendAnnouncementNotification({
    required String userId,
    required String announcementId,
    required String announcementText,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      "title": "New Announcement",
      "body": announcementText,
      "type": "announcement",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "announcementId": announcementId,
    });
  }

  static Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      "title": title,
      "body": body,
      "type": "general",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
    });
  }

  // ---------------- NEW ADDITIONS ----------------
  static Future<void> sendPostNotification({
    required String toUserId,
    required String fromUserId,
    required String postId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .add({
      "title": "New Post",
      "body": "A friend shared a new post",
      "type": "post",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "postId": postId,
      "fromUserId": fromUserId,
    });
  }

  static Future<void> sendModerationNotification({
    required String toAdminId,
    required String fromUserId,
    required String postId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toAdminId)
        .collection('notifications')
        .add({
      "title": "Moderation Alert",
      "body": "New post created by $fromUserId",
      "type": "moderation",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
      "postId": postId,
      "fromUserId": fromUserId,
    });
  }
}
