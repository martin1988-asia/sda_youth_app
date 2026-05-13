// lib/features/chat/global_chat_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sda_youth_app/services/global_chat_service.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/core/user_role.dart';

/// Global Hub Sector — High-fidelity Mass Communication Sector for SDA Youth.
/// Manages real-time community pulses with verified identity halos and sovereign moderation.
class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  // --- High-Visibility Branding Palette ---
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
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
    if (mounted) setState(() => _isAdmin = (role == UserRole.admin));
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
    await GlobalChatService.transmitMessage(text);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: premiumBlack,
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          // Cinematic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Expanded(child: _buildMessageStream(user.uid)),
                    _buildInputComposer(),
                  ],
                ),
              ),
            ),
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
        onPressed: () => context.go('/home'),
      ),
      title: const Column(
        children: [
          Text("GLOBAL HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
          Text("COMMUNITY PULSE • LIVE", style: TextStyle(color: electricTeal, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildMessageStream(String myUid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: GlobalChatService.globalStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: electricTeal));
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _avatarHalo(photo),
          const SizedBox(width: 12),
          Flexible(
            child: GestureDetector(
              onLongPress: _isAdmin ? () => _showSovereignMenu(docId) : null,
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) Text(data['senderName'] ?? 'Member', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(top: 4),
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
                    child: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ts != null ? timeago.format(ts.toDate(), locale: 'en_short').toUpperCase() : '...',
                    style: const TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 12),
          if (isMe) _avatarHalo(photo),
        ],
      ),
    );
  }

  Widget _avatarHalo(String? url) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primaryTeal, accentYellow])),
      child: CircleAvatar(radius: 14, backgroundColor: premiumBlack, backgroundImage: url != null ? NetworkImage(url) : null, child: url == null ? const Icon(Icons.person, size: 14, color: Colors.white12) : null),
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
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(hintText: "Broadcast to community...", hintStyle: TextStyle(color: Colors.white24, fontSize: 14), border: InputBorder.none),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.send_rounded, color: electricTeal, size: 24), onPressed: _handleSend),
        ],
      ),
    );
  }

  void _showSovereignMenu(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: const Text("SOVEREIGN PURGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              onTap: () {
                GlobalChatService.purgeTransmission(messageId);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
