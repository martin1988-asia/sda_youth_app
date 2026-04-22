import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart'; // ✅ import the drawer

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout(String userName) async {
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
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);

      if (!mounted) return; // ✅ safe check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Goodbye, $userName — you have been logged out.")),
      );

      if (!mounted) return; // ✅ safe check
      Navigator.pushReplacementNamed(context, '/login');
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
      "notifications": "/notifications_preferences",
      "quiet hours": "/quiet_hours",
      "data saver": "/data_saver",
      "feedback": "/feedback",
      "privacy data": "/privacy_data",
      "accessibility": "/accessibility",
      "app behavior": "/app_behavior",
      "session management": "/session_management",
      "connections": "/connections",
    };

    final route = routes[query.toLowerCase()];
    if (route != null) {
      Navigator.pushNamed(context, route);
    } else {
      if (!mounted) return; // ✅ safe check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No feature found for '$query'")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    final pages = [
      _buildHomePage(),
      _buildSpiritualPage(),
      _buildSocialPage(),
      _buildSettingsPage(),
      _buildInfoPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("SDA Youth App"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _handleSearch(_searchController.text),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      drawer: AppDrawer(isAdmin: false), // ✅ FIXED: removed const
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)), // ✅ analyzer-safe
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                return const Center(child: Text('No profile found.'));
              }

              final data = snapshot.data!.data() ?? {};
              final userName = data['name'] ?? user.displayName ?? 'Friend';

              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Image.asset('assets/sda_logo.png', height: 60),
                    Text(
                      'Welcome, $userName!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: pages[_selectedIndex]),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                      onPressed: () => _logout(userName),
                    ),
                  ],
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
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
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

  // ✅ Page builders
  Widget _buildHomePage() => const Center(
        child: Text("Home Dashboard",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      );

  Widget _buildSpiritualPage() => Center(
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

  Widget _buildSocialPage() => Center(
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

  Widget _buildSettingsPage() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ExpansionTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text("Settings & Preferences",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildTile(Icons.settings, "Settings", '/settings', Colors.deepOrange, 60),
                  _buildTile(Icons.lock, "Auth Security", '/auth_security', Colors.brown, 60),
                  _buildTile(Icons.manage_accounts, "Account Profile", '/account_profile', Colors.cyan, 60),
                  _buildTile(Icons.notifications, "Notifications", '/notifications_preferences', Colors.pink, 60),
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

  Widget _buildInfoPage() => Center(
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

  // ✅ Tile Builder with larger icons
  Widget _buildTile(IconData icon, String label, String route, Color iconColor, double iconSize) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
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

