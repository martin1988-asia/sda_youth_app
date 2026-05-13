import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/community/community_page.dart';
import '../widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _safeCrashlytics(Object e, StackTrace st, {String? reason}) async {
    try {
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(e, st, reason: reason);
      }
    } catch (_) {}
  }

  Future<void> _safeCrashlyticsLog(String msg) async {
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.log(msg);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout(String userName) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);

      await _safeCrashlyticsLog("User $userName logged out");
      await FirebaseAnalytics.instance.logEvent(
        name: "logout",
        parameters: {"userName": userName},
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text("Goodbye, $userName — you have been logged out."),
          duration: const Duration(seconds: 2),
        ),
      );

      if (!mounted) return;
      context.go('/login');
    } catch (e, stack) {
      await _safeCrashlytics(e, stack, reason: 'logout_failed');
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text("Error logging out")));
    }
  }

  void _handleSearch(String query) {
    final routes = {
      "messages": "/messages",
      "events": "/events",
      "media": "/media",
      "settings": "/settings",
      "profile": "/profile",
      "devotionals": "/devotionals",
      "favorites": "/favorites",
      "community": "/community",
      "support": "/support",
      "about": "/about",
      "auth security": "/auth_security",
      "account profile": "/account_profile",
      "notifications": "/notifications",
      "notification settings": "/notification_settings",
      "quiet hours": "/quiet_hours",
      "data saver": "/data_saver",
      "feedback": "/feedback",
      "privacy data": "/privacy_data",
      "accessibility": "/accessibility",
      "app behavior": "/app_behavior",
      "session management": "/session_management",
      "connections": "/connections",
    };

    final route = routes[query.toLowerCase().trim()];
    if (route != null) {
      FirebaseAnalytics.instance.logEvent(
        name: "search_navigation",
        parameters: {"query": query, "route": route},
      );
      context.push(route);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No feature found for '$query'")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No user logged in", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final pages = [
      _buildHomeTab(),
      _buildSpiritualTab(),
      _buildSocialTab(),
      _buildSettingsTab(),
      _buildInfoTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SDA Youth App",
          style: TextStyle(color: Colors.yellowAccent),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.yellowAccent),
            tooltip: "Search features",
            onPressed: () => _handleSearch(_searchController.text),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.yellowAccent),
            tooltip: "Profile",
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.7)),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                _safeCrashlytics(
                  snapshot.error ?? 'error',
                  snapshot.stackTrace ?? StackTrace.current,
                  reason: 'home_users_doc_stream_failed',
                );
                return const Center(
                  child: Text(
                    'Failed to load profile.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'No profile found.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final data = snapshot.data!.data() ?? {};
              final userName = (data['name'] ?? user.displayName ?? 'Friend').toString();

              return SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Image.asset(
                          'assets/sda_logo.png',
                          height: 60,
                          semanticLabel: "SDA Youth Logo",
                        ),
                        Text(
                          'Welcome, $userName!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: pages[_selectedIndex]),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                          ),
                          onPressed: () => _logout(userName),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.yellowAccent,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black87,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Spiritual"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Social"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Info"),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _notificationsBadge(uid),
              _messagesBadge(uid),
              _plainIcon(Icons.event, '/events', tooltip: "Open events"),
            ],
          ),
        ),
        const Divider(color: Colors.white54),
        const Expanded(child: CommunityPage()),
      ],
    );
  }

  Widget _plainIcon(IconData icon, String route, {String? tooltip}) {
    return IconButton(
      icon: Icon(icon, color: Colors.yellowAccent, size: 28),
      tooltip: tooltip,
      onPressed: () {
        try {
          context.push(route);
        } catch (e, stack) {
          _safeCrashlytics(e, stack, reason: "nav_failed_$route");
        }
      },
    );
  }

  Widget _badgeIcon({
    required IconData icon,
    required String route,
    required String tooltip,
    required Stream<int> countStream,
  }) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: Icon(icon, color: Colors.yellowAccent, size: 28),
              tooltip: tooltip,
              onPressed: () {
                try {
                  FirebaseAnalytics.instance.logEvent(
                    name: "open_badge_icon",
                    parameters: {"route": route, "count": count},
                  );
                  context.push(route);
                } catch (e, stack) {
                  _safeCrashlytics(e, stack, reason: "nav_failed_$route");
                }
              },
            ),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _notificationsBadge(String uid) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);

    return _badgeIcon(
      icon: Icons.notifications,
      route: '/notifications',
      tooltip: "Open notifications",
      countStream: stream,
    );
  }

  Widget _messagesBadge(String uid) {
    final stream = FirebaseFirestore.instance
        .collection('messages')
        .where('recipientId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);

    return _badgeIcon(
      icon: Icons.message,
      route: '/messages',
      tooltip: "Open messages",
      countStream: stream,
    );
  }

  Widget _buildSpiritualTab() => Center(
        child: Wrap(
          spacing: 30,
          runSpacing: 30,
          alignment: WrapAlignment.center,
          children: [
            _buildTile(Icons.book, "Devotionals", '/devotionals', Colors.green, 60),
            _buildTile(Icons.favorite, "Favorites", '/favorites', Colors.red, 60),
          ],
        ),
      );

  Widget _buildSocialTab() => Center(
        child: Wrap(
          spacing: 30,
          runSpacing: 30,
          alignment: WrapAlignment.center,
          children: [
            _buildTile(Icons.message, "Messages", '/messages', Colors.blue, 60),
            _buildTile(Icons.event, "Events", '/events', Colors.orange, 60),
            _buildTile(Icons.cloud_upload, "Media", '/media', Colors.purple, 60),
            _buildTile(Icons.group, "Community", '/community', Colors.teal, 60),
            _buildTile(Icons.person, "Profile", '/profile', Colors.indigo, 60),
          ],
        ),
      );

  Widget _buildSettingsTab() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ExpansionTile(
            leading: const Icon(Icons.settings, color: Colors.yellowAccent),
            title: const Text(
              "Settings & Preferences",
              style: TextStyle(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildTile(Icons.settings, "Settings", '/settings', Colors.deepOrange, 60),
                  _buildTile(Icons.lock, "Auth Security", '/auth_security', Colors.brown, 60),
                  _buildTile(Icons.manage_accounts, "Account Profile", '/account_profile', Colors.cyan, 60),
                  _buildTile(Icons.notifications, "Notifications", '/notifications', Colors.pink, 60),
                  _buildTile(Icons.tune, "Notification Settings", '/notification_settings', Colors.pinkAccent, 60),
                  _buildTile(Icons.nightlight, "Quiet Hours", '/quiet_hours', Colors.deepPurple, 60),
                  _buildTile(Icons.data_usage, "Data Saver", '/data_saver', Colors.lightBlue, 60),
                  _buildTile(Icons.feedback, "Feedback", '/feedback', Colors.green, 60),
                  _buildTile(Icons.privacy_tip, "Privacy Data", '/privacy_data', Colors.redAccent, 60),
                  _buildTile(Icons.accessibility, "Accessibility", '/accessibility', Colors.lime, 60),
                  _buildTile(Icons.settings_applications, "App Behavior", '/app_behavior', Colors.amber, 60),
                  _buildTile(Icons.manage_history, "Session Management", '/session_management', Colors.blueGrey, 60),
                  _buildTile(Icons.people, "Connections", '/connections', Colors.orangeAccent, 60),
                ],
              )
            ],
          ),
        ],
      );

  Widget _buildInfoTab() => Center(
        child: Wrap(
          spacing: 30,
          runSpacing: 30,
          alignment: WrapAlignment.center,
          children: [
            _buildTile(Icons.support, "Support", '/support', Colors.purple, 60),
            _buildTile(Icons.info, "About", '/about', Colors.deepPurple, 60),
          ],
        ),
      );

  Widget _buildTile(
    IconData icon,
    String label,
    String route,
    Color iconColor,
    double iconSize,
  ) {
    return GestureDetector(
      onTap: () {
        try {
          FirebaseAnalytics.instance.logEvent(
            name: "navigate_tile",
            parameters: {"label": label, "route": route},
          );
          context.push(route);
        } catch (e, stack) {
          _safeCrashlytics(e, stack, reason: "nav_failed_$route");
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor, semanticLabel: label),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
