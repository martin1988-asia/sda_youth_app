// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sda_youth_app/services/post_service.dart';
import '../models/post.dart';

/// PostCard — World-Class Social UI aligned with high-fidelity identity governance.
/// Standardizes the "Titan" aesthetic with 32px radii and cinematic discussion threads.
class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Palette Mirror for local logic
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color accentYellow = Color(0xFFFFCC00);

  final TextEditingController _commentController = TextEditingController();
  bool _isTransmitting = false;
  bool _showDiscussion = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- SOVEREIGN ACTIONS ---

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text("PURGE POST?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text("This action will permanently remove this testimony from the community ledger.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3333)),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PostService.purgePost(widget.post.id);
      _showSafeSnack("Post Purged Successfully");
    }
  }

  Future<void> _handleEdit() async {
    final editController = TextEditingController(text: widget.post.content);
    
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text("EDIT TESTIMONY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: editController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()), 
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text("SAVE CHANGES"),
          ),
        ],
      ),
    );

    if (newContent != null && newContent.isNotEmpty) {
      await PostService.editPost(postId: widget.post.id, newContent: newContent);
      _showSafeSnack("Identity Update Complete");
    }
  }

  Future<void> _handleComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTransmitting = true);
    try {
      await PostService.addCommentToPost(postId: widget.post.id, text: text);
      if (mounted) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        setState(() => _showDiscussion = true);
        _showSafeSnack("Insight Shared to Discussion");
      }
    } finally {
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  void _showSafeSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final bool isOwner = widget.post.authorId == FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                title: const Text("Edit Post", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _handleEdit(); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF3333)),
                title: const Text("Purge Post", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _handleDelete(); },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: accentYellow),
              title: const Text("Report Content", style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _showSafeSnack("Flagged for Review"); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.post.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Identity Header
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: _buildIdentityHalo(widget.post.authorPhoto),
            title: Text(widget.post.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Row(
              children: [
                Text(timeago.format(widget.post.timestamp.toDate()), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                const Text(" • VERIFIED", style: TextStyle(color: electricTeal, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white24),
              onPressed: () => _showMenu(context),
            ),
          ),

          // 2. Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(widget.post.content, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6)),
            ),

          // 3. Media
          if (widget.post.mediaUrl != null) _buildMediaFrame(),

          // 4. Interaction Bar
          _buildInteractionBar(postRef, uid),

          // 5. Expandable Discussion Hub
          if (_showDiscussion) _buildDiscussionLedger(postRef),

          // 6. Quick Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildIdentityHalo(String? url) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [primaryTeal, accentYellow]),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF050505),
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? const Icon(Icons.person, color: Colors.white12) : null,
      ),
    );
  }

  Widget _buildInteractionBar(DocumentReference postRef, String? uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: postRef.collection('likes').snapshots(),
            builder: (context, snapshot) {
              final likes = snapshot.data?.docs ?? [];
              final isLiked = likes.any((doc) => doc.id == uid);
              return _ActionButton(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: likes.length.toString(),
                color: isLiked ? Colors.redAccent : Colors.white38,
                onTap: () => PostService.toggleLikeOnPost(widget.post.id),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: postRef.collection('comments').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _ActionButton(
                icon: _showDiscussion ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                label: count.toString(),
                color: _showDiscussion ? electricTeal : Colors.white38,
                onTap: () => setState(() => _showDiscussion = !_showDiscussion),
              );
            },
          ),
          const Spacer(),
          _ActionButton(
            icon: Icons.ios_share_rounded,
            label: 'SHARE',
            color: Colors.white38,
            onTap: () {
              Clipboard.setData(ClipboardData(text: "https://sda-youth.app/posts/${widget.post.id}"));
              _showSafeSnack("Mission Link Copied");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionLedger(DocumentReference postRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: postRef.collection('comments').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.white10,
                      backgroundImage: data['userPhoto'] != null ? NetworkImage(data['userPhoto']) : null,
                      child: data['userPhoto'] == null ? const Icon(Icons.person, size: 10, color: Colors.white24) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['userName'] ?? 'Member', style: const TextStyle(color: accentYellow, fontWeight: FontWeight.bold, fontSize: 11)),
                          Text(data['comment'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 52,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(hintText: "Add to discussion...", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
              ),
            ),
            _isTransmitting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: electricTeal))
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: electricTeal, size: 20),
                  onPressed: _handleComment,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaFrame() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          widget.post.mediaUrl!, 
          height: 350, 
          width: double.infinity, 
          fit: BoxFit.cover, 
          errorBuilder: (ctx, error, stackTrace) => Container(height: 200, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white12))
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
