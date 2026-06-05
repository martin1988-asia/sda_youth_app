import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/post_service.dart';
import '../../models/post.dart';
import '../../widgets/post_card.dart';
import '../../widgets/titan_shimmer.dart';
import '../../core/theme.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ScrollController _scrollController = ScrollController();
  String _activeFilter = 'All';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: AppTheme.bg,

      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,

        onRefresh: () async => setState(() {}),

        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            /// ✅ HEADER
            _wrap(_buildHeader()),

            /// ✅ COMPOSER
            SliverToBoxAdapter(child: _wrap(_buildComposer(uid))),

            /// ✅ FILTERS
            SliverToBoxAdapter(child: _wrap(_buildFilters())),

            /// ✅ POSTS
            _buildPosts(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  /* ---------------- HEADER ---------------- */

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Community",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Share. Connect. Grow.",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  /* ---------------- COMPOSER ---------------- */

  Widget _buildComposer(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (_, snap) {
        final photo = snap.data?.data()?['userPhotoUrl'];

        return GestureDetector(
          onTap: () => context.push('/create_post'),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white12,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    "Share something with the community...",
                    style: TextStyle(color: Colors.white60),
                  ),
                ),

                const Icon(Icons.edit, color: AppTheme.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ---------------- FILTERS ---------------- */

  Widget _buildFilters() {
    final filters = ['All', 'News', 'Outreach', 'Fellowship'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final filter = filters[i];
          final selected = _activeFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) => setState(() => _activeFilter = filter),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: AppTheme.primary.withValues(alpha: 0.25),
              labelStyle: TextStyle(
                color: selected ? AppTheme.primary : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  /* ---------------- POSTS ---------------- */

  Widget _buildPosts() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PostService.postsStream(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => _wrap(const ShimmerPost()),
              childCount: 3,
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyState();
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((_, i) {
            final post = Post.fromDoc(docs[i]);
            return _wrap(PostCard(postId: post.id));
          }, childCount: docs.length),
        );
      },
    );
  }

  /* ---------------- EMPTY ---------------- */

  Widget _emptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome_outlined, size: 70, color: Colors.white10),
            SizedBox(height: 10),
            Text("No posts yet", style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  /* ---------------- WRAPPER ---------------- */

  Widget _wrap(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: child,
      ),
    );
  }
}
