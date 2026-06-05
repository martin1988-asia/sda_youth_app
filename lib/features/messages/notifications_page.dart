import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const Color bg = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            "Login required",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.tealAccent),
            onPressed: () {
              NotificationService.markAllAsRead(uid);
            },
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: NotificationService.stream(uid),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final data = doc.data();

                  return _NotificationItem(
                    id: doc.id,
                    uid: uid,
                    title: data['title'] ?? '',
                    body: data['body'] ?? '',
                    senderName: data['name'] ?? data['senderName'] ?? 'Someone',
                    postId: data['postId'], // ✅ NEW
                    type: data['type'] ?? '',
                    isRead: data['read'] ?? false,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===============================
// ✅ NOTIFICATION ITEM
// ===============================
class _NotificationItem extends StatelessWidget {
  final String id;
  final String uid;
  final String title;
  final String body;
  final String senderName;
  final String? postId; // ✅ NEW
  final String type;
  final bool isRead;

  const _NotificationItem({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    required this.senderName,
    required this.postId,
    required this.type,
    required this.isRead,
  });

  IconData _icon() {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat;
      case 'post':
        return Icons.newspaper;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor() {
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return Colors.tealAccent;
      default:
        return Colors.white70;
    }
  }

  void _handleTap(BuildContext context) {
    // ✅ mark as read
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .update({'read': true});

    // ✅ SAFE NAVIGATION (FIXES WEB CRASH)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (postId != null && postId!.isNotEmpty) {
        context.push('/post/$postId'); // ✅ OPEN POST
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body), backgroundColor: Colors.teal),
        );
      }
    });
  }

  void _delete() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? const Color(0xFF121212)
              : Colors.teal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isRead ? Colors.white12 : Colors.teal),
        ),
        child: Row(
          children: [
            Icon(_icon(), color: _iconColor()),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.close, color: Colors.white38),
              onPressed: _delete,
            ),

            if (!isRead)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.tealAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
