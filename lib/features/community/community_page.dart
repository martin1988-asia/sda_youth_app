// lib/features/community/community_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/post_service.dart';
import '../../models/post.dart';
import '../../widgets/post_card.dart';
import '../../widgets/titan_shimmer.dart';

/// Community Sector — High-fidelity Social Engine for SDA Youth.
/// Manages the primary community feed with real-time identity synchronization and shimmer loading.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  // --- High-Visibility Branding Palette ---
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);

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
    final String uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: RefreshIndicator(
        color: electricTeal,
        backgroundColor: const Color(0xFF0A0A0A),
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Mission Header
            _buildSliverHeader("For You"),

            // 2. Live Identity Composer
            SliverToBoxAdapter(child: _buildLiveComposer(context, uid)),

            // 3. Mission Category Filter Dock
            SliverToBoxAdapter(child: _buildFilterDock()),

            // 4. The High-Fidelity Feed Stream
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: PostService.postsStream(),
              builder: (context, snapshot) {
                // FIXED: Replaced standard spinner with Titan Shimmer skeletons for 0ms perceived lag
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ShimmerPost(),
                      childCount: 3,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = Post.fromDoc(docs[index]);
                      return PostCard(post: post);
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveComposer(BuildContext context, String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final photo = snapshot.data?.data()?['photoURL'];
        
        return GestureDetector(
          onTap: () => context.push('/create_post'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Identity Halo integration
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [primaryTeal, electricTeal]),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null 
                        ? const Icon(Icons.person, size: 18, color: Colors.white24) 
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Share your faith journey...",
                  style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.add_a_photo_outlined, color: electricTeal, size: 20),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildFilterDock() {
    final filters = ['All', 'News', 'Outreach', 'Fellowship'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (v) => setState(() => _activeFilter = filter),
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              selectedColor: electricTeal.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? electricTeal : Colors.white24,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? electricTeal : Colors.transparent,
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 80, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 16),
            const Text(
              "NO TRANSMISSIONS YET",
              style: TextStyle(color: Colors.white12, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
