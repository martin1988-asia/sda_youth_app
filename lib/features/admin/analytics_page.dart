// lib/features/admin/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:sda_youth_app/services/admin_service.dart';

/// Analytics Sector — High-fidelity data visualization for SDA Youth Admins.
/// Provides real-time Kingdom Metrics, growth velocity, and verified Ambassador tracking.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC); 
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

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
          
          FutureBuilder<Map<String, dynamic>>(
            future: AdminService.getKingdomSnapshot(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: electricTeal));
              }

              final stats = snapshot.data ?? {};

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 2. Growth Velocity Header
                  _buildSectionHeader("KINGDOM GROWTH VELOCITY"),
                  SliverToBoxAdapter(
                    child: _buildHealthCard(
                      stats['healthStatus'] ?? 'ACTIVE',
                      stats['newMembersThisWeek'] ?? 0,
                    ),
                  ),

                  // 3. Impact Metrics Grid
                  _buildSectionHeader("COMMUNITY IMPACT LEDGER"),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildListDelegate([
                        _buildKPICard("MEMBERS", stats['totalMembers'] ?? 0),
                        _buildKPICard("COMMUNITY POSTS", stats['totalPosts'] ?? 0),
                        _buildKPICard("PRAYER PETITIONS", stats['activePrayers'] ?? 0),
                        _buildKPICard("VICTORIES SHARED", stats['totalTestimonies'] ?? 0),
                      ]),
                    ),
                  ),

                  // 4. Top Ambassadors Sector with Identity Halos
                  _buildSectionHeader("TOP KINGDOM AMBASSADORS"),
                  _buildAmbassadorList(),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 12),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(color: electricTeal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5),
        ),
      ),
    );
  }

  Widget _buildHealthCard(String status, int newGrowth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: electricTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SYSTEM HEALTH", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(status, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("WEEKLY GROWTH", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text("+$newGrowth", style: const TextStyle(color: accentYellow, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAmbassadorList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminService.getTopAmbassadors(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final users = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = users[index];
              final String? photo = user['photoURL'];
              final String name = user['name'] ?? 'Mission Member';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [primaryTeal, electricTeal]),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: premiumBlack,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null ? const Icon(Icons.person, size: 18, color: Colors.white12) : null,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  trailing: Text("${user['xp'] ?? 0} XP", style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              );
            },
            childCount: users.length,
          ),
        );
      },
    );
  }
}
