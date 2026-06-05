// ✅ FINAL PRODUCTION CHAT SYSTEM

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../reels/reels_page.dart';

class ChatThreadPage extends StatefulWidget {
  final String otherUserId;

  const ChatThreadPage({super.key, required this.otherUserId});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late String userId;
  late String chatId;

  @override
  void initState() {
    super.initState();

    print("CHAT OPENED WITH: ${widget.otherUserId}");

    userId = FirebaseAuth.instance.currentUser!.uid;

    // ✅ deterministic chatId (same for both users)
    final ids = [userId, widget.otherUserId]..sort();
    chatId = "${ids[0]}_${ids[1]}";

    print("CHAT ID: $chatId");

    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ✅ TYPING STATE (FINAL)
  Future<void> _setTyping(bool typing) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'typing_$userId': typing,
    }, SetOptions(merge: true));
  }

  // ✅ SEND MESSAGE (FULL FIXED VERSION)
  Future<void> _sendMessage() async {
    print("SENDING MESSAGE...");
    print("SENDING TO: ${widget.otherUserId}");
    print("CHAT ID USED: $chatId");

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // ✅ 1. CREATE / UPDATE CHAT DOCUMENT (FIXES INBOX)
    await chatRef.set({
      'participants': [userId, widget.otherUserId],
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ 2. ADD MESSAGE (your existing logic)
    await chatRef.collection('messages').add({
      'senderId': userId,
      'receiverId': widget.otherUserId,
      'text': text,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("✅ MESSAGE SAVED!");

    _scrollToBottom();
  }

  // ✅ MARK AS READ
  Future<void> _markMessagesAsRead() async {
    final unread = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unread.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),

      // ✅ ✅ PREMIUM APP BAR (ONLINE + LAST SEEN)
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),

        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (_, snap) {
            final data = snap.data?.data();

            final isOnline = data?['online'] == true;
            final lastSeen = data?['lastSeen'] as Timestamp?;

            String subtitle = "Offline";

            if (isOnline) {
              subtitle = "Online";
            } else if (lastSeen != null) {
              final time = lastSeen.toDate();
              final diff = DateTime.now().difference(time);

              if (diff.inMinutes < 1) {
                subtitle = "Just now";
              } else if (diff.inMinutes < 60) {
                subtitle = "Last seen ${diff.inMinutes}m ago";
              } else {
                subtitle = "Last seen ${diff.inHours}h ago";
              }
            }

            return Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("User", style: TextStyle(fontSize: 14)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline ? Colors.greenAccent : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _markMessagesAsRead(); // ✅ REAL-TIME READ FIX
                return false;
              },
              child: _messages(),
            ),
          ),
          _typingIndicator(),
          _composer(),
        ],
      ),
    );
  }

  // ✅ REAL MESSAGE STREAM
  Widget _messages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          _markMessagesAsRead();
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Start conversation",
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data();
            final isMe = data['senderId'] == userId;
            return _bubble(data, isMe);
          },
        );
      },
    );
  }

  // ✅ MESSAGE BUBBLE (FINAL UI)
  Widget _bubble(Map<String, dynamic> data, bool isMe) {
    final ts = data['timestamp'] as Timestamp?;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00FFCC) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (data['type'] == 'reel' && data['reelId'] != null)
              GestureDetector(
                onTap: () async {
                  final reelId = data['reelId'];
           
                  if (reelId == null) return;

                  final snap = await FirebaseFirestore.instance
                      .collection('reels')
                      .doc(reelId)
                      .get();

                  if (!context.mounted) return;

                  if (!snap.exists) return;


                  Future.microtask(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReelsPage(
                          isVisible: true,
                          userId: snap.data()?['userId'],
                          startIndex: 0,
                          initialReelId: reelId,
                        ),
                      ),
                    );
                  });
                },

                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('reels')
                      .doc(data['reelId'])
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final reelData = snap.data!.data();
                    final mediaUrl =
                        reelData?['mediaUrl'] ?? reelData?['videoUrl'];

                    final isVideo = mediaUrl != null &&
                        mediaUrl.toString().toLowerCase().endsWith('.mp4');

                    return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: (mediaUrl != null && !isVideo)
                          ? DecorationImage(
                              image: NetworkImage(mediaUrl),
                              fit: BoxFit.cover,
                            )
                            : null,
                        color: Colors.black,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (data['text'] != null)
              Text(
                data['text'],
                style: TextStyle(
                  color: isMe ? Colors.black : Colors.white,
                ),
              ),

            const SizedBox(height: 6),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ts != null ? timeago.format(ts.toDate()) : "",
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    data['isRead'] == true ? Icons.done_all : Icons.check,
                    size: 14,
                    color: data['isRead'] == true
                        ? Colors.blueAccent
                        : Colors.white38,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final data = snap.data!.data();

        final isTyping = data?['typing_${widget.otherUserId}'] == true;

        if (!isTyping) return const SizedBox();

        return const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Typing...",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ COMPOSER (FINAL - PREMIUM TYPING ENABLED)
  Widget _composer() {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,

              // ✅ TYPING DETECTION
              onChanged: (text) {
                _setTyping(text.isNotEmpty);
              },

              // ✅ SEND ON ENTER
              onSubmitted: (_) {
                _setTyping(false);
                _sendMessage();
              },

              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Message...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),

          CircleAvatar(
            backgroundColor: const Color(0xFF00FFCC),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),

              // ✅ STOP TYPING BEFORE SEND
              onPressed: () {
                _setTyping(false);
                _sendMessage();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ✅ END OF CLASS (DO NOT REMOVE)
}
