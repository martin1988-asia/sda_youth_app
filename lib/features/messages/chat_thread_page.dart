// lib/features/messages/chat_thread_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../services/message_service.dart';

/// Chat Thread Sector — high-fidelity real-time communication for SDA Youth.
/// Manages peer-to-peer transmissions with a premium bubble-based interface.
class ChatThreadPage extends StatefulWidget {
  final String recipientId; // This is the Email

  const ChatThreadPage({super.key, required this.recipientId});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  // --- Branding Palette ---
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTransmitting = false;

  @override
  void initState() {
    super.initState();
    _markConversationAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to fetch recipient metadata for the header
  Future<Map<String, dynamic>> _getPeerMetadata() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user_lookup')
          .where('emailLower', isEqualTo: widget.recipientId.toLowerCase())
          .limit(1)
          .get();
      
      if (snap.docs.isNotEmpty) {
        final uid = snap.docs.first.data()['uid'];
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        return {
          'name': userDoc.data()?['name'] ?? widget.recipientId,
          'photo': userDoc.data()?['photoURL'],
        };
      }
    } catch (_) {}
    return {'name': widget.recipientId, 'photo': null};
  }

  void _markConversationAsRead() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Future.microtask(() async {
      final myUid = user.uid;
      final otherUid = await MessageService.resolveIdentityByEmail(widget.recipientId);
      if (otherUid == null || otherUid.isEmpty) return;

      final ids = [myUid, otherUid]..sort();
      final convoId = ids.join('_');

      try {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(convoId)
            .set({'unread': false}, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTransmitting = true);
    _messageController.clear();

    try {
      await MessageService.sendMessage(
        text: text,
        recipientEmail: widget.recipientId,
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transmission Interrupted"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: premiumBlack,
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildMessageStream(user.uid)),
              _buildInputComposer(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.02),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      title: FutureBuilder<Map<String, dynamic>>(
        future: _getPeerMetadata(),
        builder: (context, snapshot) {
          final String name = snapshot.data?['name'] ?? widget.recipientId;
          final String? photo = snapshot.data?['photo'];

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryTeal,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person, color: Colors.white30, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text("SECURE IDENTITY", style: TextStyle(color: electricTeal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.white24), onPressed: () {}),
        IconButton(icon: const Icon(Icons.info_outline, color: Colors.white24), onPressed: () {}),
      ],
    );
  }

  Widget _buildMessageStream(String myUid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('messages')
          .where('timestamp', isNotEqualTo: null)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: electricTeal));

        final allDocs = snapshot.data?.docs ?? [];
        final targetEmail = widget.recipientId;

        final conversationMsgs = allDocs.where((doc) {
          final data = doc.data();
          final sender = data['senderId'] as String?;
          final receiver = data['recipientId'] as String?;
          final senderEmail = data['senderEmail'] as String?;
          final recipientEmail = data['recipientEmail'] as String?;

          return (sender == myUid && (recipientEmail == targetEmail)) ||
                 (receiver == myUid && (senderEmail == targetEmail));
        }).toList();

        if (conversationMsgs.isEmpty) return const Center(child: Text("No transmissions in this thread yet.", style: TextStyle(color: Colors.white24)));

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: conversationMsgs.length,
          itemBuilder: (context, index) => _buildMessageBubble(conversationMsgs[index].data(), conversationMsgs[index].data()['senderId'] == myUid),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final ts = data['timestamp'] as Timestamp?;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4, bottom: 4, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? primaryTeal : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text((data['text'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(ts != null ? timeago.format(ts.toDate(), locale: 'en_short') : "...", style: const TextStyle(color: Colors.white12, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputComposer() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12, left: 16, right: 16, top: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), border: const Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(hintText: "Enter transmission...", hintStyle: TextStyle(color: Colors.white24, fontSize: 14), border: InputBorder.none),
                onSubmitted: (_) { if (!_isTransmitting) _handleSend(); },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isTransmitting ? null : _handleSend,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: primaryTeal,
              child: _isTransmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
