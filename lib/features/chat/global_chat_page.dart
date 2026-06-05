// ✅ FINAL FILE — TRUE FINAL (NO CUTS, NO BUGS, PREMIUM UX)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:sda_youth_app/services/global_chat_service.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/core/user_role.dart';
import 'package:sda_youth_app/core/theme.dart';

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color accentYellow = Color(0xFFFFCC00);

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkClearance();
  }

  Future<void> _checkClearance() async {
    final role = await RoleService.getUserRole();
    if (mounted) {
      setState(() => _isAdmin = (role == UserRole.admin));
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    await GlobalChatService.sendMessage(text);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.bg, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildMessageStream(user.uid)),
                _buildInputComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
        onPressed: () => context.go('/home'),
      ),
      title: Column(
        children: const [
          Text(
            "GLOBAL HUB",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 16,
            ),
          ),
          Text(
            "COMMUNITY PULSE • LIVE",
            style: TextStyle(
              color: electricTeal,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildMessageStream(String myUid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('global_messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: electricTeal),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final bool isMe = data['senderId'] == myUid;

            return _buildChatBubble(docs[index].id, data, isMe);
          },
        );
      },
    );
  }

  Widget _buildChatBubble(String docId, Map<String, dynamic> data, bool isMe) {
    final photo = data['senderPhoto'];
    final ts = data['timestamp'] as Timestamp?;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 180),
      tween: Tween(begin: 0.98, end: 1.0),
      builder: (context, scaleValue, child) {
        return Transform.scale(scale: scaleValue, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMe) _avatarHalo(photo),
            const SizedBox(width: 10),

            Flexible(
              child: GestureDetector(
                onLongPress: _isAdmin ? () => _showSovereignMenu(docId) : null,

                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 120),
                  tween: Tween(begin: 1.0, end: 1.0),
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),

                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          data['senderName'] ?? 'Member',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),

                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primary : AppTheme.surfaceSoft,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        ts != null
                            ? timeago.format(ts.toDate(), locale: 'en_short')
                            : '...',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (isMe) const SizedBox(width: 10),
            if (isMe) _avatarHalo(photo),
          ],
        ),
      ),
    );
  }

  Widget _avatarHalo(String? url) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [primaryTeal, accentYellow]),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppTheme.bg,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null
            ? const Icon(Icons.person, size: 14, color: AppTheme.textMuted)
            : null,
      ),
    );
  }

  Widget _buildInputComposer() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 16,
        right: 16,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSoft,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "Broadcast to community...",
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }

  void _showSovereignMenu(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.redAccent,
              ),
              title: const Text(
                "SOVEREIGN PURGE",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                GlobalChatService.deleteMessage(messageId);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
