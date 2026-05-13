// lib/home/search_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../widgets/post_card.dart';

/// Discovery Hub — World-class Search Architecture for SDA Youth.
/// Categorizes results into Identities (Members) and Wisdom (Feed Content).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
    if (_query.isNotEmpty) {
      FirebaseAnalytics.instance.logEvent(
        name: "identity_search_query",
        parameters: {"query": _query},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: _buildPremiumSearchBar(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: electricTeal,
          labelColor: accentYellow,
          unselectedLabelColor: Colors.white24,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11),
          tabs: const [
            Tab(text: "IDENTITIES"),
            Tab(text: "WISDOM"),
          ],
        ),
      ),
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
                child: _query.isEmpty 
                  ? _buildDiscoveryHint() 
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUserResults(),
                        _buildPostResults(),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        cursorColor: accentYellow,
        decoration: InputDecoration(
          hintText: "Search name or username...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: electricTeal, size: 22),
          suffixIcon: _query.isNotEmpty ? IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDiscoveryHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 100, color: Colors.white.withValues(alpha: 0.03)),
          const SizedBox(height: 20),
          const Text("DISCOVER THE MISSION", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 14)),
          const Text("Search for members or spiritual insights", style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_lookup')
          .where('usernameLower', isGreaterThanOrEqualTo: _query)
          .where('usernameLower', isLessThanOrEqualTo: '$_query\uf8ff')
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: electricTeal));
        final users = snapshot.data?.docs ?? [];
        if (users.isEmpty) return _buildNoResults();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildIdentityResultCard(users[index].data() as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildPostResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_posts').orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: electricTeal));
        final allDocs = snapshot.data?.docs ?? [];
        final filteredDocs = allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['content']?.toString().toLowerCase().contains(_query) ?? false).toList();
        if (filteredDocs.isEmpty) return _buildNoResults();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) => PostCard(post: Post.fromDoc(filteredDocs[index] as DocumentSnapshot<Map<String, dynamic>>)),
        );
      },
    );
  }

  Widget _buildIdentityResultCard(Map<String, dynamic> data) {
    // FIX: Pulling photoURL from the lookup record to show the user's real face
    final photo = data['photoURL']; 
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primaryTeal, electricTeal])),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.black,
            backgroundImage: photo != null ? NetworkImage(photo.toString()) : null,
            child: photo == null ? const Icon(Icons.person, color: Colors.white10) : null,
          ),
        ),
        title: Text((data['displayName'] ?? 'Verified Identity').toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text((data['church'] ?? 'SDA Youth Community').toString().toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        trailing: Icon(Icons.chevron_right_rounded, color: electricTeal.withValues(alpha: 0.5)),
        onTap: () => context.push('/profile'),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("NO MATCHES FOUND", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          Text("Query: '$_query'", style: const TextStyle(color: Colors.white10, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
