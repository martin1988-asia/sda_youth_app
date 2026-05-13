// lib/features/messages/messages_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sda_youth_app/services/message_service.dart';

/// Messaging Hub — High-fidelity Communication Sector for SDA Youth.
/// Manages real-time transmissions across Inbox, Outbox, and Draft sectors.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  int _selectedSector = 0; // 0: Inbox, 1: Outbox, 2: Drafts
  final List<String> _labels = ["INBOX", "SENT", "DRAFTS"];

  // Helper to fetch other user metadata for the list view
  Future<Map<String, dynamic>> _getPeerMetadata(String? email) async {
    if (email == null) return {'name': 'Unknown Identity', 'photo': null};
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user_lookup')
          .where('emailLower', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (snap.docs.isNotEmpty) {
        final uid = snap.docs.first.data()['uid'];
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        return {
          'name': userDoc.data()?['name'] ?? email,
          'photo': userDoc.data()?['photoURL'],
        };
      }
    } catch (_) {}
    return {'name': email, 'photo': null};
  }

  Future<void> _handleDelete(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("PURGE TRANSMISSION?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("This will permanently remove the message from your ledger.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MessageService.deleteMessage(messageId);
        _showFeedback("Transmission Purged");
      } catch (_) {
        _showFeedback("Purge Failed", isError: true);
      }
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? errorRed : electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: premiumBlack,
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
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildSectorDock(),
                    Expanded(child: _buildTransmissionStream(user.uid)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/compose_message'),
        backgroundColor: primaryTeal,
        elevation: 12,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text("NEW TRANSMISSION", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("MESSAGES", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: electricTeal),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorDock() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = _selectedSector == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSector = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? electricTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _labels[index],
                  style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransmissionStream(String uid) {
    Stream<QuerySnapshot<Map<String, dynamic>>> stream;
    switch (_selectedSector) {
      case 0: stream = MessageService.inboxStream(uid); break;
      case 1: stream = MessageService.outboxStream(uid); break;
      default: stream = MessageService.draftsStream(uid);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: electricTeal));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(_selectedSector == 0 ? "No Incoming Signals" : "No Transmissions Found");

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildMessageCard(docs[index], uid),
        );
      },
    );
  }

  Widget _buildMessageCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, String uid) {
    final data = doc.data();
    final text = (data['text'] ?? '').toString();
    final senderEmail = data['senderEmail']?.toString();
    final recipientEmail = data['recipientEmail']?.toString();
    final isRead = data['read'] == true;
    final ts = data['timestamp'] as Timestamp?;
    final String? otherEmail = uid == data['senderId'] ? recipientEmail : senderEmail;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getPeerMetadata(otherEmail),
      builder: (context, meta) {
        final String name = meta.data?['name'] ?? otherEmail ?? 'Mission Member';
        final String? photo = meta.data?['photo'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildIdentityAvatar(photo, !isRead && _selectedSector == 0),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(ts != null ? timeago.format(ts.toDate()) : "Synchronizing...", style: const TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: uid == data['senderId'] ? IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.white10), onPressed: () => _handleDelete(doc.id)) : null,
            onTap: () {
              if (otherEmail != null) {
                if (_selectedSector == 0) MessageService.markAsRead(doc.id);
                context.push('/messages/$otherEmail');
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildIdentityAvatar(String? url, bool unread) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: unread ? electricTeal : Colors.white12, width: 2),
          ),
          child: CircleAvatar(radius: 22, backgroundColor: Colors.white12, backgroundImage: url != null ? NetworkImage(url) : null, child: url == null ? const Icon(Icons.person, color: Colors.white24) : null),
        ),
        if (unread) Positioned(right: 2, top: 2, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: electricTeal, shape: BoxShape.circle, border: Border.all(color: premiumBlack, width: 2)))),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off_rounded, color: Colors.white.withValues(alpha: 0.05), size: 80),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
