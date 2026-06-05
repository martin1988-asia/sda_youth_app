// lib/features/messages/messages_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:sda_youth_app/services/message_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);
  static const Color accent = Color(0xFF00FFCC);

  int _selected = 0;
  final List<String> tabs = ["Chats", "Sent", "Drafts"];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildStream(user.uid)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/compose_message'),
        backgroundColor: accent,
        icon: const Icon(Icons.edit, color: Colors.black),
        label: const Text("Message", style: TextStyle(color: Colors.black)),
      ),
    );
  }

  // ✅ Tabs
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _selected == i;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? accent : card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ✅ Stream
  Widget _buildStream(String uid) {
    Stream<QuerySnapshot<Map<String, dynamic>>> stream;

    if (_selected == 0) {
      stream = MessageService.inboxStream(uid);
    } else if (_selected == 1) {
      stream = MessageService.outboxStream(uid);
    } else {
      stream = MessageService.draftsStream(uid);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No messages yet",
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: docs.length,
          itemBuilder: (_, i) => _tile(docs[i], uid),
        );
      },
    );
  }

  // ✅ Message Tile
  Widget _tile(QueryDocumentSnapshot<Map<String, dynamic>> doc, String uid) {
    final data = doc.data();

    final senderId = data['senderId'];
    final senderEmail = data['senderEmail'];
    final recipientEmail = data['recipientEmail'];

    final isMe = senderId == uid;
    final other = isMe ? recipientEmail : senderEmail;

    final text = data['text'] ?? '';
    final ts = data['timestamp'] as Timestamp?;
    final unread = data['read'] != true;

    return InkWell(
      onTap: () {
        if (other != null) {
          if (!isMe) {
            MessageService.markAsRead(doc.id);
          }
          context.push('/messages/$other');
        }
      },
      onLongPress: () => MessageService.deleteMessage(doc.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _avatar(unread && !isMe),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other ?? "User",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ts != null ? timeago.format(ts.toDate()) : "...",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 6),
                if (unread && !isMe)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(bool unread) {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, color: Colors.white54),
        ),
        if (unread)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
