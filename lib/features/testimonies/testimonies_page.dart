// lib/features/testimonies/testimonies_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Testimonies Hub — High-fidelity Spiritual Victory Sector.
/// Manages community stories with verified identity metadata stamps.
class TestimoniesPage extends StatefulWidget {
  const TestimoniesPage({super.key});

  @override
  State<TestimoniesPage> createState() => _TestimoniesPageState();
}

class _TestimoniesPageState extends State<TestimoniesPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final _testimonyController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _testimonyController.dispose();
    super.dispose();
  }

  Future<void> _submitTestimony() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _testimonyController.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      // 1. Fetch Verified Metadata from the Ledger
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String verifiedName = userDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';
      final String? verifiedPhoto = userDoc.data()?['photoURL'] ?? user.photoURL;

      // 2. Publish Story with verified identity stamp
      await FirebaseFirestore.instance.collection('testimonies').add({
        'userId': user.uid,
        'userName': verifiedName,
        'userPhoto': verifiedPhoto,
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
      });

      _testimonyController.clear();
      await FirebaseAnalytics.instance.logEvent(name: "testimony_shared");

      if (mounted) {
        _showFeedback("Victory Shared with Community");
        FocusScope.of(context).unfocus();
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handleLike(DocumentReference ref) async {
    await ref.update({'likes': FieldValue.increment(1)});
  }

  void _showFeedback(String msg) {
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

  @override
  Widget build(BuildContext context) {
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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildComposer()),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text(
                          "LATEST VICTORIES",
                          style: TextStyle(color: accentYellow, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('testimonies')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildTestimonyCard(docs[index]),
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text("WITNESS HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildComposer() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              final photo = snapshot.data?.data()?['photoURL'];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryTeal,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  const Text("SHARE A VICTORY", style: TextStyle(color: electricTeal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _testimonyController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: "How has God moved in your life today?",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: accentYellow)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submitTestimony,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("PUBLISH STORY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonyCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['userName'] ?? 'Mission Member').toString();
    final content = (data['content'] ?? '').toString();
    final likes = data['likes'] ?? 0;
    final photo = data['userPhoto'];
    final ts = data['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white12,
                backgroundImage: photo != null ? NetworkImage(photo.toString()) : null,
                child: photo == null ? const Icon(Icons.person, color: Colors.white24, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      ts != null ? timeago.format(ts.toDate()).toUpperCase() : "RECENT", 
                      style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.auto_awesome, color: accentYellow, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              InkWell(
                onTap: () => _handleLike(doc.reference),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(likes.toString(), style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white24, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ],
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
            Icon(Icons.auto_awesome_outlined, color: Colors.white12, size: 80),
            SizedBox(height: 16),
            Text("NO STORIES YET", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text("Be the first to witness to the community.", style: TextStyle(color: Colors.white10, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
