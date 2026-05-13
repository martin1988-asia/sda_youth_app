// lib/features/friends/friends_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/notifications_helper.dart';

/// Friends Hub — High-fidelity Identity Network for SDA Youth.
/// Manages peer connections, verified identity requests, and community growth.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  final _searchController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- IDENTITY LOOKUP ENGINE (Source of Truth: 'users' collection) ---
  Future<Map<String, String?>> _lookupIdentity(String value, {bool byUid = false}) async {
    try {
      String? targetUid = value;

      // 1. Resolve UID if searching by Username
      if (!byUid) {
        final lookupSnap = await FirebaseFirestore.instance
            .collection('user_lookup')
            .where('usernameLower', isEqualTo: value.trim().toLowerCase())
            .limit(1)
            .get();
        if (lookupSnap.docs.isEmpty) return {};
        targetUid = lookupSnap.docs.first.data()['uid']?.toString();
      }

      if (targetUid == null) return {};

      // 2. Fetch Verified Metadata from the 'users' ledger
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
      if (!userDoc.exists) return {'uid': targetUid};

      final d = userDoc.data()!;
      return {
        'uid': targetUid,
        'name': (d['name'] ?? 'Mission Member').toString(),
        'photo': d['photoURL']?.toString(),
      };
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      return {};
    }
  }

  // --- TRANSMISSION LOGIC ---
  Future<void> _initiateConnection() async {
    final target = _searchController.text.trim();
    if (target.isEmpty) return;

    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final identity = await _lookupIdentity(target, byUid: false);
      final targetUid = identity['uid'];

      if (targetUid == null) {
        _showFeedback("Identity Not Found in Ledger", isError: true);
      } else if (targetUid == user.uid) {
        _showFeedback("Self-Connection Restricted", isError: true);
      } else {
        await FirebaseFirestore.instance.collection('connections').add({
          'fromUserId': user.uid,
          'toUserId': targetUid,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Pull verified name for the notification
        final myDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final myName = myDoc.data()?['name'] ?? user.displayName ?? 'A Peer';

        await NotificationsHelper.sendFriendRequestNotification(
          toUserId: targetUid,
          fromUserId: user.uid,
          fromUserName: myName,
        );

        _searchController.clear();
        _showFeedback("Connection Request Transmitted");
        FirebaseAnalytics.instance.logEvent(name: 'connection_request_sent');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateConnection(String docId, String status, String targetUid) async {
    try {
      if (status == 'declined' || status == 'removed') {
        await FirebaseFirestore.instance.collection('connections').doc(docId).delete();
      } else {
        await FirebaseFirestore.instance.collection('connections').doc(docId).update({'status': status});
        await NotificationsHelper.sendGeneralNotification(
          userId: targetUid,
          title: "CONNECTION ESTABLISHED",
          body: "Your identity request was accepted.",
          data: {"route": "/friends"},
        );
      }
      _showFeedback("Identity Network Updated");
    } catch (e) {
      _showFeedback("Sync Error", isError: true);
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator()));

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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildSearchHub(),
                      ),
                    ),
                    _buildSectionHeader("Pending Verification"),
                    _buildRequestStream(user.uid),
                    _buildSectionHeader("Identity Network"),
                    _buildFriendsStream(user.uid),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("IDENTITY HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      actions: [
        IconButton(
          icon: const Icon(Icons.hub_outlined, color: electricTeal),
          onPressed: () => context.push('/connections'),
        ),
      ],
    );
  }

  Widget _buildSearchHub() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: "Enter username to expand network...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: const Icon(Icons.person_add_outlined, color: electricTeal),
          suffixIcon: IconButton(
            icon: _isProcessing 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accentYellow))
              : const Icon(Icons.send_rounded, color: accentYellow),
            onPressed: _isProcessing ? null : _initiateConnection,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Text(title.toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildRequestStream(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('connections').where('toUserId', isEqualTo: uid).where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final docs = snapshot.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildIdentityCard(docs[index], isRequest: true),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildFriendsStream(String uid) {
    final stream = FirebaseFirestore.instance.collection('connections').where('status', isEqualTo: 'accepted').snapshots();
    
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }
        final docs = snapshot.data?.docs.where((d) => d['fromUserId'] == uid || d['toUserId'] == uid).toList() ?? [];
        
        if (docs.isEmpty) return _buildEmptyState();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildIdentityCard(docs[index], isRequest: false),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildIdentityCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool isRequest}) {
    final data = doc.data();
    final user = FirebaseAuth.instance.currentUser;
    final otherUid = data['fromUserId'] == user?.uid ? data['toUserId'] : data['fromUserId'];

    return FutureBuilder<Map<String, String?>>(
      future: _lookupIdentity(otherUid.toString(), byUid: true),
      builder: (context, snap) {
        final identity = snap.data ?? {};
        final name = identity['name'] ?? 'Loading Identity...';
        final photo = identity['photo'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryTeal.withValues(alpha: 0.5))),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1A1A1A),
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person, color: Colors.white10, size: 20) : null,
              ),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(isRequest ? "Pending Connection" : "Identity Verified", style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
            trailing: isRequest 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check_circle, color: electricTeal, size: 28), onPressed: () => _updateConnection(doc.id, 'accepted', otherUid.toString())),
                    IconButton(icon: const Icon(Icons.cancel, color: errorRed, size: 28), onPressed: () => _updateConnection(doc.id, 'declined', otherUid.toString())),
                  ],
                )
              : IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white12), onPressed: () => _updateConnection(doc.id, 'removed', otherUid.toString())),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, color: Colors.white.withValues(alpha: 0.05), size: 80),
            const SizedBox(height: 16),
            const Text("Your Network is Quiet", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
