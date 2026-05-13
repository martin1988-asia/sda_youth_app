// lib/features/admin/admin_overview_page.dart
import 'package:flutter/material.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/core/user_role.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

// Sector Sub-pages
import 'analytics_page.dart';
import 'moderation_page.dart';
import 'manage_content_page.dart';

/// Flagship Admin Overview — Unified Command Hub for the SDA Youth Ecosystem.
/// Orchestrates the three primary administrative pillars: Insights, Security, and Resources.
class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage>
    with SingleTickerProviderStateMixin {
  
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Logging logic for administrative triage
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final sectors = ['Insights', 'Security', 'Resources'];
        final sectorName = sectors[_tabController.index];
        
        FirebaseAnalytics.instance.logEvent(
          name: 'admin_sector_switch',
          parameters: {'sector': sectorName},
        );
        
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.log('Sovereign Access: $sectorName Sector');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

        // Strict Role Verification
        if (!snapshot.hasData || snapshot.data != UserRole.admin) {
          return _buildRestrictedView(context);
        }

        return Scaffold(
          backgroundColor: premiumBlack,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/sda_logo.png', height: 28),
                const SizedBox(width: 12),
                const Text(
                  "MISSION CONTROL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            bottom: _buildPremiumTabBar(),
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
              
              // 2. Fragmented Content View (Safe Area ensures zero clipping)
              SafeArea(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    AnalyticsPage(),      // Pillar: Insights
                    ModerationPage(),     // Pillar: Security
                    ManageContentPage(),  // Pillar: Resources
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildPremiumTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: electricTeal,
      indicatorWeight: 4,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: accentYellow,
      unselectedLabelColor: Colors.white24,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 10),
      tabs: const [
        Tab(icon: Icon(Icons.insights_outlined, size: 20), text: "INSIGHTS"),
        Tab(icon: Icon(Icons.gpp_maybe_outlined, size: 20), text: "SECURITY"),
        Tab(icon: Icon(Icons.inventory_2_outlined, size: 20), text: "RESOURCES"),
      ],
    );
  }

  Widget _buildRestrictedView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 80),
            const SizedBox(height: 24),
            const Text(
              "ACCESS RESTRICTED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Text(
              "Administrative credentials required for this sector.",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("RETURN TO BASE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
