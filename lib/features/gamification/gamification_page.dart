// lib/features/gamification/gamification_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/gamification_service.dart';

/// Honor Sector — World-class Achievement Hub for SDA Youth.
/// Manages Kingdom XP, Mission Ranks, and the verified Digital Trophy Case.
class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
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
    if (_user == null) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator()));

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
                    
                    // 2. Real-Time XP & Rank Header (Passing UID correctly)
                    SliverToBoxAdapter(child: _buildLiveAuraHeader(_user!.uid)),

                    // 3. Trophy Case Sector
                    _buildSectionHeader("Kingdom Honors"),
                    _buildBadgesGrid(),

                    // 4. Mission Leaderboard
                    _buildSectionHeader("Global Leaderboard"),
                    _buildLeaderboardStream(),

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
      title: const Text("HONOR SECTOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      centerTitle: true,
    );
  }

  Widget _buildLiveAuraHeader(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: GamificationService.getUserProgressStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final int xp = data['xp'] ?? 0;
        final String rank = (data['rank'] ?? "Seeker").toString().toUpperCase();
        final double progress = (xp % 1000) / 1000;

        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160, height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: electricTeal,
                    ),
                  ),
                  _buildIdentityCircle(data['photoURL']),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "$xp XP",
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: electricTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: electricTeal.withValues(alpha: 0.2)),
                ),
                child: Text(
                  rank,
                  style: const TextStyle(color: electricTeal, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await GamificationService.awardXp(10, "Manual Energy Sync");
                  _showFeedback("+10 SPIRITUAL ENERGY SYNCED");
                },
                icon: const Icon(Icons.bolt, color: Colors.black, size: 20),
                label: const Text("SYNC ENERGY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentYellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdentityCircle(String? photoUrl) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [primaryTeal, accentYellow]),
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: premiumBlack,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white10) : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Text(title.toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: GamificationService.getMyBadgesStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Text("No Kingdom Honors earned yet.", style: TextStyle(color: Colors.white10, fontStyle: FontStyle.italic)),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final badge = docs[index].data();
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: electricTeal.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: accentYellow, size: 32),
                      const SizedBox(height: 10),
                      Text(
                        (badge['title'] ?? 'Honor').toString().toUpperCase(), 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('xp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        final docs = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data = docs[index].data();
              return _buildLeaderCard(index + 1, data);
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildLeaderCard(int rank, Map<String, dynamic> data) {
    Color rankColor = Colors.white24;
    if (rank == 1) {
      rankColor = accentYellow;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    }

    final photo = data['photoURL'];
    final name = data['name'] ?? 'Verified Identity';
    final int xp = data['xp'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: rank <= 3 ? rankColor.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rank <= 3 ? rankColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("#$rank", style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white10,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? const Icon(Icons.person, size: 18, color: Colors.white24) : null,
            ),
          ],
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: Text("$xp XP", style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
      ),
    );
  }
}
