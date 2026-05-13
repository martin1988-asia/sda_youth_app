// lib/features/community/about_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

/// About Hub — High-fidelity Mission Manifesto Sector for SDA Youth.
/// Defines the spiritual vision, core community pillars, and platform identity.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  Future<void> _launchPortal(BuildContext context, String url, String event) async {
    final uri = Uri.parse(url);
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (success) {
        await FirebaseAnalytics.instance.logEvent(name: event);
      } else {
        if (context.mounted) _showFeedback(context, "Portal Connection Failed");
      }
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  void _showFeedback(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: accentYellow,
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
                    _buildAppBar(context),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // 2. Identity Hero Header
                            _buildHeroHeader(),

                            const SizedBox(height: 40),

                            // 3. Mission & Vision Sectors
                            _buildManifestoCard(
                              "The Mission", 
                              "To empower Seventh-day Adventist youth with a high-fidelity platform that fosters spiritual growth, community synergy, and global mission impact.",
                              Icons.auto_awesome_outlined, // Fixed typo
                            ),

                            const SizedBox(height: 16),

                            _buildManifestoCard(
                              "The Vision", 
                              "A unified, faith-centered digital community where every SDA youth can thrive spiritually and contribute to the Great Commission.",
                              Icons.visibility_outlined, // Fixed typo
                            ),

                            const SizedBox(height: 40),

                            // 4. Pillars of Faith Grid
                            _buildSectionLabel("Core Community Pillars"),
                            const SizedBox(height: 16),
                            _buildPillarsGrid(),

                            const SizedBox(height: 40),

                            // 5. System Metadata Ledger
                            _buildSectionLabel("Identity Metadata"),
                            const SizedBox(height: 16),
                            _buildMetadataLedger(context),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("MANIFESTO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [primaryTeal, accentYellow]),
          ),
          child: Hero(
            tag: 'app_logo',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: premiumBlack,
              child: Image.asset('assets/sda_logo.png', height: 60),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "SDA YOUTH APP", 
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)
        ),
        const Text(
          "PROTOCOL v1.0.0 PREMIUM", 
          style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)
        ),
      ],
    );
  }

  Widget _buildManifestoCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentYellow, size: 20),
              const SizedBox(width: 12),
              Text(title.toUpperCase(), style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(), 
        style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)
      ),
    );
  }

  Widget _buildPillarsGrid() {
    final List<Map<String, dynamic>> pillars = [
      {'label': 'FAITH', 'icon': Icons.church_outlined},
      {'label': 'UNITY', 'icon': Icons.groups_3_outlined},
      {'label': 'SERVICE', 'icon': Icons.volunteer_activism_outlined},
      {'label': 'GROWTH', 'icon': Icons.trending_up_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
      ),
      itemCount: pillars.length,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(pillars[index]['icon'], color: electricTeal, size: 18),
            const SizedBox(width: 12),
            Text(pillars[index]['label'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataLedger(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _metadataTile("Lead Architect", "MARTIN", Icons.verified_user_outlined),
          const Divider(color: Colors.white10, height: 24),
          _metadataTile("Terms of Spiritual Service", "View Covenant", Icons.gavel_rounded, onTap: () => _launchPortal(context, "https://sda-youth-app.org/terms", "terms_viewed")),
          const Divider(color: Colors.white10, height: 24),
          _metadataTile("Privacy Protocol", "View Ledger", Icons.privacy_tip_outlined, onTap: () => _launchPortal(context, "https://sda-youth-app.org/privacy", "privacy_viewed")),
        ],
      ),
    );
  }

  Widget _metadataTile(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: primaryTeal, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Spacer(),
          if (onTap != null) const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
        ],
      ),
    );
  }
}
