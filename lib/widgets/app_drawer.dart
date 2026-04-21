import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  final bool isAdmin;
  const AppDrawer({super.key, required this.isAdmin});

  Future<void> _handleLogout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? "User";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Logout")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Goodbye, $userName — you have been logged out.")),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Logout failed: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text(
              "SDA Youth App",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          _drawerItem(context, Icons.home, "Home", '/home'),
          _drawerItem(context, Icons.person, "My Profile", '/profile'),
          _drawerItem(context, Icons.article, "My Posts", '/my_posts'),
          _drawerItem(context, Icons.book, "Devotionals", '/devotionals'),
          _drawerItem(context, Icons.event, "Events", '/events'),
          _drawerItem(context, Icons.message, "Messages", '/messages'),
          _drawerItem(context, Icons.group, "Community", '/community'),
          _drawerItem(context, Icons.announcement, "Announcements", '/announcements'),
          _drawerItem(context, Icons.star, "Testimonies", '/testimonies'),
          _drawerItem(context, Icons.school, "Lessons", '/lessons'),
          _drawerItem(context, Icons.book_online, "Bible", '/bible'),
          _drawerItem(context, Icons.church, "Prayer", '/prayer'),
          _drawerItem(context, Icons.gamepad, "Gamification", '/gamification'),
          _drawerItem(context, Icons.lightbulb, "Learning", '/learning'),
          _drawerItem(context, Icons.hub, "Resource Hub", '/resource_hub'),
          const Divider(),
          _drawerItem(context, Icons.feedback, "Feedback", '/feedback'),
          _drawerItem(context, Icons.support, "Support", '/support'),
          _drawerItem(context, Icons.info, "About", '/about'),
          _drawerItem(context, Icons.settings, "Settings", '/settings'),
          _drawerItem(context, Icons.privacy_tip, "Privacy & Data", '/privacy_data'),
          _drawerItem(context, Icons.notifications, "Notifications Preferences", '/notifications_preferences'),
          _drawerItem(context, Icons.security, "Auth Security", '/auth_security'),
          _drawerItem(context, Icons.accessibility, "Accessibility", '/accessibility'),
          _drawerItem(context, Icons.data_saver_on, "Data Saver", '/data_saver'),
          _drawerItem(context, Icons.sync, "Sync Reset", '/sync_reset'),
          _drawerItem(context, Icons.developer_mode, "Developer Options", '/developer_options'),
          _drawerItem(context, Icons.timer, "Quiet Hours", '/quiet_hours'),
          _drawerItem(context, Icons.manage_accounts, "Session Management", '/session_management'),
          if (isAdmin) ...[
            const Divider(),
            _drawerItem(context, Icons.admin_panel_settings, "Admin Dashboard", '/admin_dashboard'),
            _drawerItem(context, Icons.people, "Manage Users", '/manage_users'),
            _drawerItem(context, Icons.content_copy, "Manage Content", '/manage_content'),
            _drawerItem(context, Icons.shield, "Moderation", '/moderation'),
            _drawerItem(context, Icons.analytics, "Analytics", '/analytics'),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
