// ✅ FULL FILE — UPGRADED WITHOUT REMOVING FEATURES

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log out"),
        content: const Text("Do you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Log Out"),
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
    final uid = user?.uid ?? "";

    return Drawer(
      backgroundColor: AppTheme.bg,
      child: Column(
        children: [
          /// ✅ HEADER (UNCHANGED BUT CLEANED)
          if (uid.isNotEmpty)
            _LiveDrawerHeader(uid: uid)
          else
            const SizedBox(height: 150),

          /// ✅ CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _section("My Activity"),
                _navTile(
                  context,
                  Icons.inventory_2_outlined,
                  "My Posts",
                  "/my_posts",
                ),
                _navTile(context, Icons.star_border, "Favorites", "/favorites"),
                _navTile(
                  context,
                  Icons.emoji_events_outlined,
                  "Achievements",
                  "/gamification",
                ),

                _section("Community"),
                _navTile(context, Icons.info_outline, "About", "/about"),
                _navTile(
                  context,
                  Icons.feedback_outlined,
                  "Feedback",
                  "/feedback",
                ),
                _navTile(context, Icons.support_agent, "Support", "/support"),

                if (uid.isNotEmpty) _admin(context, uid),

                _section("Settings"),
                _navTile(context, Icons.settings, "Settings", "/settings"),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

          /// ✅ FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
            child: _logoutTile(context),
          ),
        ],
      ),
    );
  }

  /* ================= SECTION ================= */

  Widget _section(String label, {bool isCritical = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isCritical ? Colors.redAccent : accentYellow,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  /* ================= TILE ================= */

  Widget _navTile(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final selected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white.withValues(alpha: selected ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (Navigator.canPop(context)) Navigator.pop(context);

            context.push(route);

            FirebaseAnalytics.instance.logEvent(
              name: 'drawer_nav_click',
              parameters: {'dest': route},
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),

            leading: Icon(
              icon,
              color: selected ? electricTeal : Colors.white38,
            ),

            title: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),

            trailing: selected
                ? Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: electricTeal,
                      shape: BoxShape.circle,
                    ),
                  )
                : const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.white24,
                  ),
          ),
        ),
      ),
    );
  }

  /* ================= ADMIN ================= */

  Widget _admin(BuildContext context, String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (_, snap) {
        final role = snap.data?.data()?['role'] ?? 'user';

        if (role != 'admin') return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Admin Tools", isCritical: true),

            _navTile(
              context,
              Icons.dashboard_outlined,
              "Admin Dashboard",
              "/admin_dashboard",
            ),

            _navTile(context, Icons.security, "Moderation", "/moderation"),

            _navTile(context, Icons.group, "Manage Users", "/manage_users"),
          ],
        );
      },
    );
  }

  /* ================= LOGOUT ================= */

  Widget _logoutTile(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleLogout(context),
        child: const ListTile(
          leading: Icon(Icons.logout, color: Colors.redAccent),
          title: Text(
            "Log out",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/* ================= HEADER (FULLY PRESERVED) ================= */

class _LiveDrawerHeader extends StatefulWidget {
  final String uid;
  const _LiveDrawerHeader({required this.uid});

  @override
  State<_LiveDrawerHeader> createState() => _LiveDrawerHeaderState();
}

class _LiveDrawerHeaderState extends State<_LiveDrawerHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) {
      return const SizedBox(height: 150);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() ?? {};

        final name = data['name'] ?? "User";
        final photoUrl = data['userPhotoUrl'];
        final role = (data['role'] ?? 'user').toString().toUpperCase();

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: const Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              /// ✅ ANIMATED HALO (KEPT)
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  return Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppDrawer.electricTeal,
                          AppDrawer.accentYellow.withValues(
                            alpha: _controller.value,
                          ),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                  );
                },
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(
                        color: AppDrawer.electricTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
}
