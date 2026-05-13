// lib/features/devotionals/favorites_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

/// Favorites Hub — High-fidelity Spiritual Archive for SDA Youth.
/// Manages the personal ledger of saved insights and daily manna.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  Future<void> _handlePurge(DocumentReference<Map<String, dynamic>> favRef) async {
    try {
      await favRef.delete();
      if (mounted) {
        _showFeedback("Wisdom Token Removed from Vault");
      }
    } catch (_) {
      if (mounted) {
        _showFeedback("Purge Protocol Failed", isError: true);
      }
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
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
    if (user == null) {
      return const Scaffold(
        backgroundColor: premiumBlack,
        body: Center(child: Text("Identity Verification Required", style: TextStyle(color: Colors.white38))),
      );
    }

    final favoritesQuery = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('itemType', isEqualTo: 'devotional')
        .orderBy('timestamp', descending: true);

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
                    
                    // 2. Vault Status Header
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Text(
                          "PERSONAL WISDOM VAULT",
                          style: TextStyle(
                            color: electricTeal, 
                            fontSize: 11, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 3
                          ),
                        ),
                      ),
                    ),

                    // 3. The Favorites Stream
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: favoritesQuery.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator(color: electricTeal)),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildFavoriteLoader(docs[index]),
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),
                    
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
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("SAVED INSIGHTS", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildFavoriteLoader(QueryDocumentSnapshot<Map<String, dynamic>> favDoc) {
    final devotionalId = (favDoc.data()['itemId'] ?? favDoc.id).toString();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('devotionals').doc(devotionalId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink(); 
        }

        final data = snapshot.data!.data()!;
        return _buildWisdomCard(data, favDoc.reference);
      },
    );
  }

  Widget _buildWisdomCard(Map<String, dynamic> data, DocumentReference<Map<String, dynamic>> ref) {
    final title = (data['title'] ?? 'Daily Manna').toString().toUpperCase();
    final verse = (data['verse'] ?? '').toString();
    final date = data['date'];
    String dateText = "IDENTITY LOGGED";
    
    if (date is Timestamp) {
      dateText = DateFormat('MMMM dd, yyyy').format(date.toDate()).toUpperCase();
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateText, 
                style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
              ),
              const Icon(Icons.bookmark_added_rounded, color: electricTeal, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title, 
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            verse, 
            style: const TextStyle(color: accentYellow, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _actionButton("READ AGAIN", Icons.auto_stories_outlined, primaryTeal, () => context.push('/devotionals')),
              const SizedBox(width: 12),
              _actionButton("PURGE", Icons.delete_outline_rounded, Colors.white10, () => _handlePurge(ref), isError: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isError = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isError ? errorRed : Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                label, 
                style: TextStyle(
                  color: isError ? errorRed : Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 11, 
                  letterSpacing: 1.5
                ),
              ),
            ],
          ),
        ),
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
            Icon(Icons.bookmark_border_rounded, color: Colors.white12, size: 80),
            SizedBox(height: 16),
            Text("VAULT IS EMPTY", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
