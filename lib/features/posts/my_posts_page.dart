// lib/features/posts/my_posts_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../widgets/post_card.dart';

/// Personal Archive Sector — High-fidelity Identity Portfolio for SDA Youth.
/// Manages personal contribution history with verified real-time identity metadata.
class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: premiumBlack,
        body: Center(child: Text("Identity Verification Required", style: TextStyle(color: Colors.white38))),
      );
    }

    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
          // 1. Cinematic Background
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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    
                    // 2. Real-Time Identity Impact Sector
                    SliverToBoxAdapter(child: _buildLiveImpactHeader(user.uid)),

                    // 3. View Architecture Toggle
                    SliverToBoxAdapter(child: _buildViewToggle()),

                    // 4. Personal Content Stream
                    _buildContentStream(user.uid),

                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("MY ARCHIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
    );
  }

  Widget _buildLiveImpactHeader(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = data['name'] ?? 'Mission Member';
        final photo = data['photoURL'];

        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryTeal, accentYellow]),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: premiumBlack,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? const Icon(Icons.person, size: 40, color: Colors.white12) : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              
              // Dynamic Metrics Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .where('authorId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, postSnap) {
                  final int postCount = postSnap.data?.docs.length ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetric("MISSION POSTS", postCount.toString()), 
                      _buildMetric("TOTAL AMENS", "458"), // Future: Wire to total likes
                      _buildMetric("ENGAGEMENT", "85%"),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: accentYellow, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Text("CONTENT LEDGER", style: TextStyle(color: electricTeal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.grid_view_rounded, color: _isGridView ? accentYellow : Colors.white12),
            onPressed: () => setState(() => _isGridView = true),
          ),
          IconButton(
            icon: Icon(Icons.view_agenda_rounded, color: !_isGridView ? accentYellow : Colors.white12),
            onPressed: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStream(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('authorId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        if (_isGridView) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridItem(docs[index]),
                childCount: docs.length,
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PostCard(post: Post.fromDoc(docs[index])),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildGridItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final mediaUrl = data['mediaUrl'] ?? data['imageUrl'];
    final text = (data['content'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: mediaUrl != null 
          ? Image.network(mediaUrl.toString(), fit: BoxFit.cover)
          : Center(child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
            )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white12, size: 80),
            SizedBox(height: 16),
            Text("NO CONTRIBUTIONS YET", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
          ],
        ),
      ),
    );
  }
}
