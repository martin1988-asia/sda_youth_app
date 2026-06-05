// ✅ FULL VISUAL UPGRADE — LOGIC UNTOUCHED

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/follow_service.dart';
import '../widgets/post_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  static const Color bg = Color(0xFF0A0A0A);

  final TextEditingController _controller = TextEditingController();
  late TabController _tab;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    final q = val.trim().toLowerCase();
    setState(() => _query = q);

    if (q.isNotEmpty) {
      FirebaseAnalytics.instance.logEvent(
        name: "search_query",
        parameters: {"query": q},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),

        // ✅ SEARCH BAR UPGRADED
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _searchBar(),
        ),

        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.tealAccent,
          tabs: const [
            Tab(text: "People"),
            Tab(text: "Posts"),
          ],
        ),
      ),

      body: _query.isEmpty
          ? _suggestedUsers()
          : TabBarView(controller: _tab, children: [_users(), _posts()]),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearch,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
          hintText: "Search people or posts",
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () {
                    _controller.clear();
                    _onSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ✅ FIXED WIDTH + BETTER DESIGN
  Widget _suggestedUsers() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .limit(15)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs
                .where((doc) => doc.id != currentUserId)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              children: [
                const Text(
                  "Suggested users",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                ...docs.map((doc) => _userCard(doc.data(), doc.id)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _users() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs.where((doc) {
              if (doc.id == currentUserId) return false;

              final name = (doc.data()['name'] ?? '').toLowerCase();
              return name.contains(_query);
            }).toList();

            if (docs.isEmpty) return _noResults();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final doc = docs[i];
                return _userCard(doc.data(), doc.id);
              },
            );
          },
        ),
      ),
    );
  }

  // ✅ ELITE USER CARD 🔥
  Widget _userCard(Map<String, dynamic> data, String userId) {
    final photo = data['profileImageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/profile_view/$userId');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[800],
                  child: ClipOval(
                    child:
                        (photo != null && photo.toString().startsWith('http'))
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          )
                        : const Icon(Icons.person),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        data['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                StreamBuilder<bool>(
                  stream: FollowService.isFollowing(userId),
                  builder: (_, snap) {
                    final isFollowing = snap.data ?? false;

                    return ElevatedButton(
                      onPressed: () {
                        FollowService.toggleFollow(userId);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: isFollowing
                            ? Colors.grey[700]
                            : Colors.tealAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isFollowing ? "Following" : "Follow",
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _posts() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = snap.data!.docs.where((doc) {
              final text = doc.data()['content']?.toLowerCase() ?? '';
              return text.contains(_query);
            }).toList();

            if (filtered.isEmpty) return _noResults();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 30),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final doc = filtered[i];

                return PostCard(key: ValueKey(doc.id), postId: doc.id);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _noResults() {
    return Center(
      child: Text(
        "No results for \"$_query\"",
        style: const TextStyle(color: Colors.white38),
      ),
    );
  }
}
