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

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  static const Color teal = Color(0xFF00FFCC);
  static const Color red = Color(0xFFFF3333);
  static const Color bg = Color(0xFF050505);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  bool _isProcessing = false;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final r = await RoleService.getUserRole();
    if (mounted) setState(() => _isAuthorized = (r == UserRole.admin));
  }

  // ✅ CENTRAL ACTION HANDLER
  Future<void> _handleAction(String uid, String name, String action) async {
    setState(() => _isProcessing = true);

    try {
      if (action == "warn") {
        await _warnUser(uid);
      }

      if (action == "ban") {
        await AdminService.setMemberRole(uid, 'banned');

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'status': 'banned',
        });

        _show("User banned 🚫", error: true);
      }

      if (action == "delete") {
        final confirm = await _confirm("Delete $name permanently?");
        if (confirm == true) {
          await AdminService.terminateUserIdentity(uid);
          _show("User deleted ❌", error: true);
        }
      }

      if (action == "message") {
        await _message(uid, name);
      }

      FirebaseAnalytics.instance.logEvent(
        name: 'admin_action',
        parameters: {'action': action},
      );
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ✅ AUTO MODERATION WARNING SYSTEM
  Future<void> _warnUser(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((t) async {
      final snap = await t.get(ref);

      final currentWarnings = (snap.data()?['warnings'] ?? 0) as int;
      final newWarnings = currentWarnings + 1;

      t.update(ref, {
        'warnings': newWarnings,
        'lastWarning': FieldValue.serverTimestamp(),
      });

      // ✅ AUTO-BAN AFTER 3 WARNINGS
      if (newWarnings >= 3) {
        t.update(ref, {'status': 'banned', 'role': 'banned'});
      }
    });

    // ✅ NOTIFICATION
    await NotificationsHelper.sendGeneralNotification(
      userId: uid,
      title: "Warning",
      body: "You have received a warning from admin.",
      data: {'route': '/notifications'},
    );

    final updatedUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final warnings = updatedUser.data()?['warnings'] ?? 0;

    if (warnings >= 3) {
      await NotificationsHelper.sendGeneralNotification(
        userId: uid,
        title: "Account Restricted",
        body: "You have been banned due to repeated violations.",
        data: {'route': '/home'},
      );

      _show("User auto-banned (3 warnings) 🚫", error: true);
    } else {
      _show("Warning issued ⚠️");
    }
  }

  // ✅ MESSAGE USER
  Future<void> _message(String uid, String name) async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Message $name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Send"),
          ),
        ],
      ),
    );

    if (ok == true && controller.text.isNotEmpty) {
      final admin = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': admin?.uid,
        'recipientId': uid,
        'text': controller.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationsHelper.sendGeneralNotification(
        userId: uid,
        title: "Admin Message",
        body: controller.text,
        data: {'route': '/messages'},
      );
    }
  }

  Future<bool?> _confirm(String text) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _show(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? red : teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _search(),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search users...",
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: teal),
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _list() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = s.data!.docs.where((d) {
          final str = "${d['name']} ${d['church']} ${d['region']}"
              .toLowerCase();
          return str.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) => _user(users[i]),
        );
      },
    );
  }

  Widget _user(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    final warnings = d['warnings'] ?? 0;
    final status = d['status'] ?? "active";

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(d['name'] ?? "", style: const TextStyle(color: Colors.white)),
      subtitle: Row(
        children: [
          if (status == "banned") _badge("BANNED", red),
          if (warnings > 0 && status != "banned")
            _badge("WARN $warnings", Colors.orange),
        ],
      ),
      trailing: _isProcessing
          ? const CircularProgressIndicator()
          : PopupMenuButton<String>(
              onSelected: (a) => _handleAction(doc.id, d['name'] ?? "", a),
              itemBuilder: (_) => const [
                PopupMenuItem(value: "message", child: Text("Message")),
                PopupMenuItem(value: "warn", child: Text("Warn")),
                PopupMenuItem(value: "ban", child: Text("Ban")),
                PopupMenuItem(value: "delete", child: Text("Delete")),
              ],
            ),
    );
  }

  Widget _badge(String text, Color c) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: c, fontSize: 10)),
    );
  }
}
