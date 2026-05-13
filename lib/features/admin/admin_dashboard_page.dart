// lib/features/admin/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/services/admin_service.dart';
import 'package:sda_youth_app/core/user_role.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Admin Dashboard — Sovereign Command & Analytics Hub for SDA Youth.
/// Provides real-time Kingdom metrics and absolute control over community data.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  // High-Visibility Design Palette
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: RoleService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: premiumBlack,
            body: Center(child: CircularProgressIndicator(color: primaryTeal)),
          );
        }

        // Nuclear Security Check
        if (!snapshot.hasData || snapshot.data != UserRole.admin) {
          return _buildAccessDenied(context);
        }

        return Scaffold(
          backgroundColor: premiumBlack,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              "COMMAND HUB",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16),
            ),
          ),
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
                        // 2. Live Intelligence Metrics Snapshot
                        SliverToBoxAdapter(child: _buildLiveMetricsBar()),

                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 30, 24, 16),
                            child: Text(
                              "SOVEREIGN CONTROL TOOLS",
                              style: TextStyle(color: electricTeal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                          ),
                        ),

                        // 3. Command Grid
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                            delegate: SliverChildListDelegate([
                              _AdminGridTile(
                                icon: Icons.people_outline,
                                title: "Personnel Hub",
                                route: "/manage_users",
                                color: accentYellow,
                              ),
                              _AdminGridTile(
                                icon: Icons.gpp_maybe_outlined,
                                title: "Security Queue",
                                route: "/moderation",
                                color: Colors.redAccent,
                              ),
                              _AdminGridTile(
                                icon: Icons.auto_awesome_motion,
                                title: "Content Ledger",
                                route: "/manage_content",
                                color: Colors.purpleAccent,
                              ),
                              _AdminGridTile(
                                icon: Icons.analytics_outlined,
                                title: "Kingdom Metrics",
                                route: "/admin_overview",
                                color: Colors.blueAccent,
                              ),
                              _AdminGridTile(
                                icon: Icons.insights_outlined,
                                title: "Deep Analytics",
                                route: "/analytics",
                                color: electricTeal,
                              ),
                              _AdminGridTile(
                                icon: Icons.settings_suggest_outlined,
                                title: "System Keys",
                                route: "/settings",
                                color: Colors.grey,
                              ),
                            ]),
                          ),
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
      },
    );
  }

  Widget _buildLiveMetricsBar() {
    return FutureBuilder<Map<String, int>>(
      future: AdminService.getGlobalMetrics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final members = data['totalMembers']?.toString() ?? '...';
        final posts = data['totalPosts']?.toString() ?? '...';
        final testimonies = data['totalTestimonies']?.toString() ?? '...';
        final prayers = data['activePrayers']?.toString() ?? '...';

        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem("MEMBERS", members),
                  _metricItem("INSIGHTS", posts),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem("VICTORIES", testimonies, color: Colors.purpleAccent),
                  _metricItem("PETITIONS", prayers, color: electricTeal),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _metricItem(String label, String value, {Color color = accentYellow}) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            const Text("RESTRICTED SECTOR", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Administrator verification failed.", style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/home'), 
              style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
              child: const Text("EXIT SECTOR"),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminGridTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  const _AdminGridTile({
    required this.icon,
    required this.title,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        FirebaseAnalytics.instance.logEvent(name: 'admin_nav', parameters: {'page': route});
        if (!kIsWeb) FirebaseCrashlytics.instance.log('Navigating to $route');
        context.push(route);
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
