// lib/features/admin/manage_users_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/services/admin_service.dart';
import 'package:sda_youth_app/core/user_role.dart';
import 'package:sda_youth_app/notifications_helper.dart';

/// User Management Sector — High-Fidelity Responsive Identity Control.
/// Provides sovereign authority over community identities and roles.
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isProcessing = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorization() async {
    final r = await RoleService.getUserRole();
    if (mounted) setState(() => _isAuthorized = (r == UserRole.admin));
  }

  Future<void> _handleAction(String uid, String name, String action) async {
    setState(() => _isProcessing = true);
    try {
      switch (action) {
        case "dm": 
          _sendDirectMessage(uid, name); 
          break;
        case "mod": 
          await AdminService.setMemberRole(uid, 'moderator');
          _showFeedback("Identity Elevated to Moderator");
          break;
        case "ban": 
          await AdminService.setMemberRole(uid, 'banned'); 
          await FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'banned'});
          _showFeedback("Access Revoked for Identity");
          break;
        case "del": 
          final confirmed = await _showConfirmPurge(name);
          if (confirmed == true) {
            await AdminService.terminateUserIdentity(uid);
            _showFeedback("Identity Purged from Ledgers", isError: true);
          }
          break;
      }
      FirebaseAnalytics.instance.logEvent(name: 'admin_sovereign_action', parameters: {'action': action});
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendDirectMessage(String toUid, String name) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("GUIDANCE TO $name", style: const TextStyle(color: accentYellow, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter administrative guidance...",
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.black26,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text("SEND SIGNAL"),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty && mounted) {
      final admin = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': admin?.uid,
        'recipientId': toUid,
        'text': controller.text.trim(),
        'status': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
      });
      await NotificationsHelper.sendGeneralNotification(
        userId: toUid,
        title: "ADMINISTRATIVE GUIDANCE",
        body: controller.text.trim(),
        data: {'route': '/messages'},
      );
    }
  }

  Future<bool?> _showConfirmPurge(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("PROTOCOL ALPHA?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text("Confirm total erasure of $name from all community ledgers? This cannot be undone.", style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: errorRed), child: const Text("PURGE")),
        ],
      ),
    );
  }

  void _showFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? errorRed : electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return const Scaffold(
        backgroundColor: premiumBlack,
        body: Center(child: CircularProgressIndicator(color: electricTeal)),
      );
    }

    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
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
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildSearchHub(),
                    Expanded(child: _buildUserStream()),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(), // Fixed: Standard Navigator pop
          ),
          const Text("PERSONNEL HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchHub() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: "Search Identity, Church or Region...",
            hintStyle: TextStyle(color: Colors.white24),
            prefixIcon: Icon(Icons.search, color: electricTeal),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildUserStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: electricTeal));
        }

        final users = snapshot.data?.docs.where((doc) {
          final d = doc.data();
          final searchStr = "${d['name']} ${d['church']} ${d['region']}".toLowerCase();
          return searchStr.contains(_searchQuery);
        }).toList() ?? [];

        if (users.isEmpty) return _buildEmptyState();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index]),
        );
      },
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final String name = (data['name'] ?? 'Verified Identity').toString();
    final String role = (data['role'] ?? 'user').toString();
    final String status = (data['status'] ?? 'active').toString();
    final String church = (data['church'] ?? 'Global Community').toString();
    final String? photo = data['photoURL'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [primaryTeal, role == 'user' ? Colors.white10 : electricTeal]),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: premiumBlack,
            backgroundImage: photo != null ? NetworkImage(photo.toString()) : null,
            child: photo == null ? const Icon(Icons.person, color: Colors.white12) : null,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
            if (role != 'user') _buildBadge(role.toUpperCase(), electricTeal),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(church.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            if (status == 'banned') _buildBadge("BANNED", errorRed) else _buildBadge("ACTIVE", Colors.greenAccent),
          ],
        ),
        trailing: _isProcessing 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: electricTeal))
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white24),
              color: const Color(0xFF1A1A1A), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (action) => _handleAction(doc.id, name, action),
              itemBuilder: (ctx) => [
                _buildMenuItem("dm", "Issue Guidance", Icons.mail_outline, electricTeal),
                _buildMenuItem("mod", "Promote to Moderator", Icons.shield_outlined, Colors.blueAccent),
                _buildMenuItem("ban", "Restrict Access", Icons.block_flipped, Colors.orangeAccent),
                _buildMenuItem("del", "Sovereign Purge", Icons.delete_forever_outlined, errorRed),
              ],
            ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String val, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))]),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, color: Colors.white.withValues(alpha: 0.05), size: 100),
          const SizedBox(height: 16),
          const Text("NO IDENTITY MATCHES", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }
}

