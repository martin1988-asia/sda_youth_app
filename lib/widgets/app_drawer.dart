// lib/widgets/app_drawer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Command Hub Drawer — High-fidelity Sovereign Navigation.
/// Focused on utility, governance, and admin sectors to avoid Home Page duplication.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("TERMINATE SESSION?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: const Text("Securely sign out of your digital identity?", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("LOGOUT"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Drawer(
      backgroundColor: Colors.black.withValues(alpha: 0.98),
      child: Column(
        children: [
          // 1. Real-time Identity Header (Only build if UID exists)
          if (uid.isNotEmpty) _LiveDrawerHeader(uid: uid) else const SizedBox(height: 150),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                // --- SECTOR 1: PERSONAL LEDGER ---
                _buildSectorLabel("Personal Ledger"),
                _navTile(context, Icons.inventory_2_outlined, "My Archive", "/my_posts"),
                _navTile(context, Icons.stars_rounded, "Sacred Markers", "/favorites"),
                _navTile(context, Icons.workspace_premium_outlined, "Honor Sector", "/gamification"),

                // --- SECTOR 2: THE COMMUNITY ---
                _buildSectorLabel("Community Hub"),
                _navTile(context, Icons.info_outline_rounded, "Our Manifesto", "/about"),
                _navTile(context, Icons.feedback_outlined, "Mission Feedback", "/feedback"),
                _navTile(context, Icons.support_agent_rounded, "Support Center", "/support"),

                // --- SECTOR 3: SOVEREIGN CONTROL (Admin Only) ---
                if (uid.isNotEmpty) _buildAdminSector(uid),
                
                // --- SECTOR 4: GOVERNANCE ---
                _buildSectorLabel("Governance"),
                _navTile(context, Icons.tune_rounded, "System Settings", "/settings"),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildAdminSector(String uid) {
    // SOVEREIGN GUARD: Prevent empty string path error on logout
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        // Safe check for data availability
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        
        final role = snapshot.data?.data()?['role'] ?? 'user';
        if (role != 'admin') return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectorLabel("Mission Control", isCritical: true),
            _navTile(context, Icons.dashboard_customize_outlined, "Sovereign Dashboard", "/admin_dashboard"),
            _navTile(context, Icons.gpp_maybe_outlined, "Security Queue", "/moderation"),
            _navTile(context, Icons.groups_2_outlined, "Personnel Hub", "/manage_users"),
          ],
        );
      },
    );
  }

  Widget _buildSectorLabel(String label, {bool isCritical = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isCritical ? Colors.redAccent : accentYellow,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String label, String route) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final bool isSelected = currentRoute == route;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(
        icon, 
        color: isSelected ? electricTeal : Colors.white30, 
        size: 22
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70, 
          fontSize: 14, 
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      trailing: isSelected 
        ? Container(width: 4, height: 4, decoration: const BoxDecoration(color: electricTeal, shape: BoxShape.circle)) 
        : const Icon(Icons.chevron_right_rounded, color: Colors.white10, size: 16),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
        FirebaseAnalytics.instance.logEvent(name: 'drawer_nav_click', parameters: {'dest': route});
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10, top: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 22),
        title: const Text(
          "TERMINATE SESSION", 
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)
        ),
        onTap: () => _handleLogout(context),
      ),
    );
  }
}

class _LiveDrawerHeader extends StatefulWidget {
  final String uid;
  const _LiveDrawerHeader({required this.uid});

  @override
  State<_LiveDrawerHeader> createState() => _LiveDrawerHeaderState();
}

class _LiveDrawerHeaderState extends State<_LiveDrawerHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SOVEREIGN GUARD: Stop rendering if ID is empty
    if (widget.uid.isEmpty) return const SizedBox(height: 150);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
           return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        }
        
        final data = snapshot.data?.data() ?? {};
        final name = data['name'] ?? "Mission Member";
        final photoUrl = data['photoURL'];
        final roleStr = (data['role'] ?? 'user').toString().toUpperCase();

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 70, 24, 30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: const Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              _buildIdentityHalo(photoUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roleStr,
                      style: const TextStyle(color: AppDrawer.electricTeal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdentityHalo(String? photoUrl) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [const Color(0xFF00FFCC), const Color(0xFFFFCC00).withValues(alpha: _controller.value)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
            child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white10, size: 28) : null,
          ),
        );
      },
    );
  }
}
