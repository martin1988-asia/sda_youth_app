// ✅ FULL FILE — UPGRADED + SAFE (NOTHING REMOVED)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../services/post_service.dart';

class PostCard extends StatefulWidget {
  final String postId;

  const PostCard({super.key, required this.postId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool _showHeart = false;
  double _pressScale = 1.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scale = Tween<double>(
      begin: 0.7,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  void _handleLike() {
    PostService.toggleLikeOnPost(widget.postId);

    setState(() => _showHeart = true);

    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream(String? uid) {
    if (uid == null || uid.isEmpty) return null;

    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .doc(widget.postId)
              .snapshots(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 150);
            }

            final data = snapshot.data!.data() ?? {};

            final String? authorId = data['authorId'];
            final isOwner = authorId == currentUser?.uid;

            final int likeCount = data['likeCount'] ?? 0;
            final int commentCount = data['commentCount'] ?? 0;
            final String content = data['content'] ?? '';
            final String authorName = data['authorName'] ?? 'User';
            final String? mediaUrl = data['mediaUrl'];
            final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

            return GestureDetector(
              onTapDown: (_) => setState(() => _pressScale = 0.97),
              onTapUp: (_) => setState(() => _pressScale = 1.0),
              onTapCancel: () => setState(() => _pressScale = 1.0),
              onDoubleTap: _handleLike,
              child: AnimatedScale(
                scale: _pressScale,
                duration: const Duration(milliseconds: 140),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// ✅ MAIN CARD
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSoft,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ✅ HEADER (SAFE + CORRECT)
                          Builder(
                            builder: (_) {
                              if (authorId == null || authorId.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: const [
                                      CircleAvatar(
                                        radius: 22,
                                        child: Icon(Icons.person),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Unknown User",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>
                              >(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(authorId)
                                    .snapshots(),
                                builder: (_, userSnap) {
                                  final userData = userSnap.data?.data() ?? {};
                                  final imageUrl = userData['userPhotoUrl']
                                      ?.toString();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.white12,
                                          backgroundImage:
                                              (imageUrl != null &&
                                                  imageUrl.startsWith('http'))
                                              ? NetworkImage(imageUrl)
                                              : null,
                                          child: imageUrl == null
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                authorName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                timeago.format(
                                                  timestamp.toDate(),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (isOwner)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              PostService.purgePost(
                                                widget.postId,
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          /// ✅ TEXT CONTENT
                          if (content.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],

                          /// ✅ MEDIA
                          if (mediaUrl != null &&
                              mediaUrl.toString().isNotEmpty) ...[
                            const SizedBox(height: 12),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    mediaUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          /// ✅ ACTION BAR
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: _handleLike,
                                ),
                                Text('$likeCount'),

                                const SizedBox(width: 14),

                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: AppTheme.surface,
                                      builder: (_) =>
                                          _CommentsSheet(postId: widget.postId),
                                    );
                                  },
                                ),
                                Text('$commentCount'),

                                const Spacer(),

                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    final text =
                                        "$content\n\nhttps://sda-youth.app/posts/${widget.postId}";
                                    SharePlus.instance.share(
                                      ShareParams(text: text),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// ✅ HEART ANIMATION
                    if (_showHeart)
                      ScaleTransition(
                        scale: _scale,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 90,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// ✅ COMMENTS — FULLY PRESERVED + CLEANED
////////////////////////////////////////////////////////////////

class _CommentsSheet extends StatefulWidget {
  final String postId;

  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  void _sendComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    PostService.addCommentToPost(postId: widget.postId, text: text);

    _controller.clear();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Comments",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: PostService.commentsStream(widget.postId),
                  builder: (_, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data();

                        return ListTile(
                          title: Text(
                            data['userName'] ?? '',
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                          subtitle: Text(
                            data['comment'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: "Write comment...",
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primary),
                      onPressed: _sendComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
