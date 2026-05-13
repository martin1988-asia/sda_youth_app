// lib/features/prayer/prayer_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/prayer_service.dart';

/// Prayer Hub — High-fidelity Intercession Sector for SDA Youth.
/// Manages community petitions with verified identity metadata and real-time category intelligence.
class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  final _requestController = TextEditingController();
  String _activeCategory = 'General';
  bool _isAnonymous = false;
  bool _isPosting = false;

  final List<String> _categories = ['General', 'Healing', 'Guidance', 'Faith', 'Family', 'Thanksgiving'];

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submitPrayer() async {
    final text = _requestController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final ref = await PrayerService.transmitPetition(
        text: text, 
        category: _activeCategory, 
        isAnonymous: _isAnonymous
      );

      if (ref != null && mounted) {
        _requestController.clear();
        setState(() => _isAnonymous = false);
        _showFeedback("Petition Transmitted to Community");
        FocusScope.of(context).unfocus();
        await FirebaseAnalytics.instance.logEvent(name: "prayer_requested");
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
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
    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
          // Cinematic Background
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
                    
                    // 1. Interactive Prayer Composer
                    SliverToBoxAdapter(child: _buildComposer()),

                    // 2. Intelligence Filter Dock
                    SliverToBoxAdapter(child: _buildCategoryDock()),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
                        child: Text(
                          "COMMUNITY PRAYER WALL",
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),

                    // 3. High-Performance Intercession Stream
                    _buildIntercessionStream(),
                    
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
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text("PRAYER HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildComposer() {
    final user = FirebaseAuth.instance.currentUser;
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
          Row(
            children: [
              // Live Identity Snap
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  final photo = snapshot.data?.data()?['photoURL'];
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryTeal,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              const Text("POUR OUT YOUR HEART", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Spacer(),
              _buildAnonymityToggle(),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _requestController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "How can the community lift you up today?",
              hintStyle: const TextStyle(color: Colors.white12),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: accentYellow)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submitPrayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("TRANSMIT PETITION", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDock() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (v) => setState(() => _activeCategory = cat),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: electricTeal,
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnonymityToggle() {
    return InkWell(
      onTap: () => setState(() => _isAnonymous = !_isAnonymous),
      child: Row(
        children: [
          Text("ANONYMOUS", style: TextStyle(color: _isAnonymous ? electricTeal : Colors.white12, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(_isAnonymous ? Icons.visibility_off : Icons.visibility, color: _isAnonymous ? electricTeal : Colors.white12, size: 16),
        ],
      ),
    );
  }

  Widget _buildIntercessionStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PrayerService.petitionsStream(category: _activeCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPrayerCard(docs[index]),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildPrayerCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final String name = (data['userName'] ?? 'Mission Member').toString();
    final String request = (data['request'] ?? '').toString();
    final String category = (data['category'] ?? 'General').toString();
    final int count = data['supportCount'] ?? 0;
    final String? photo = data['userPhoto'];
    final ts = data['timestamp'] as Timestamp?;
    final bool isMine = data['userId'] == FirebaseAuth.instance.currentUser?.uid;
    final bool isAnon = data['isAnonymous'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              _buildAvatar(photo, isAnon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(ts != null ? timeago.format(ts.toDate()).toUpperCase() : "NOW", style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              _buildCategoryBadge(category),
            ],
          ),
          const SizedBox(height: 20),
          Text(request, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              _amenButton(count, () => PrayerService.pulseAmen(doc.id, data['userId'])),
              const Spacer(),
              if (isMine) 
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white12, size: 20), 
                  onPressed: () => PrayerService.purgePetition(doc.id)
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, bool isAnon) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: isAnon ? [Colors.white10, Colors.white10] : [primaryTeal, accentYellow]),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.black,
        backgroundImage: (url != null && !isAnon) ? NetworkImage(url) : null,
        child: (url == null || isAnon) ? Icon(isAnon ? Icons.person_off : Icons.person, color: Colors.white24, size: 20) : null,
      ),
    );
  }

  Widget _buildCategoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentYellow.withValues(alpha: 0.2)),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _amenButton(int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: electricTeal.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: electricTeal.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volunteer_activism, color: electricTeal, size: 18), 
            const SizedBox(width: 10),
            const Text("AMEN", style: TextStyle(color: electricTeal, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(width: 8),
            Text(count.toString(), style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
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
            Icon(Icons.auto_awesome_outlined, color: Colors.white10, size: 80),
            SizedBox(height: 16),
            Text("NO PETITIONS FOUND", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
