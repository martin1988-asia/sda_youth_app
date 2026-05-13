// lib/features/media/media_library_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Digital Library — World-class Sermon & Media Hub for SDA Youth.
/// Manages cinematic video archives, spiritual podcasts, and community music.
class MediaLibraryPage extends StatefulWidget {
  const MediaLibraryPage({super.key});

  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color premiumBlack = Color(0xFF050505);

  String _selectedCategory = 'Sermons';
  final List<String> _categories = ['Sermons', 'Podcasts', 'Music', 'Seminars'];

  @override
  Widget build(BuildContext context) {
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                
                // 2. Featured "Hero" Asset
                SliverToBoxAdapter(child: _buildFeaturedHero()),

                // 3. Category Intelligence Dock
                SliverToBoxAdapter(child: _buildCategoryDock()),

                // 4. The High-Fidelity Media Stream
                _buildMediaStream(),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
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
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("MEDIA VAULT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
      actions: [
        IconButton(
          icon: const Icon(Icons.cast_connected_outlined, color: electricTeal),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFeaturedHero() {
    return Container(
      height: 220,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: const DecorationImage(
          image: AssetImage('assets/background.jpg'), 
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Colors.black87, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FEATURED SERMON", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 4),
            const Text("THE FINAL FRONTIER", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(
              children: [
                _heroAction(Icons.play_arrow_rounded, "WATCH NOW", accentYellow, Colors.black),
                const SizedBox(width: 12),
                _heroAction(Icons.add, "MY LIST", Colors.white10, Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroAction(IconData icon, String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: text, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildCategoryDock() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: electricTeal,
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontWeight: FontWeight.w900, fontSize: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('media_library')
          .where('category', isEqualTo: _selectedCategory)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMediaCard(docs[index]),
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: DecorationImage(image: NetworkImage(data['thumbnail'] ?? ''), fit: BoxFit.cover),
              ),
              child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(data['speaker'] ?? 'Speaker', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("Transmitting new spiritual content...", style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
