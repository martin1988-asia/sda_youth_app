// lib/features/settings/session_management_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Session Management — High-fidelity Identity Control for SDA Youth.
/// Provides real-time oversight of authorized devices and security tokens.
class SessionManagementPage extends StatefulWidget {
  const SessionManagementPage({super.key});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  Future<void> _terminateSession(DocumentReference sessionRef) async {
    try {
      await sessionRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session Revoked Successfully"), backgroundColor: primaryTeal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Termination Failed")));
      }
    }
  }

  Future<void> _terminateAllSessions(User user) async {
    final confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All Unauthorized Sessions Purged"), backgroundColor: primaryTeal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purge Failed")));
      }
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("REVOKE ALL ACCESS?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("This will terminate your identity session on all devices. You will be required to re-authenticate.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("PURGE ALL"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: premiumBlack,
        body: Center(child: Text("Identity Verification Required", style: TextStyle(color: Colors.white38))),
      );
    }

    final sessionsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('lastActive', descending: true);

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
                    _buildAppBar(),
                    
                    // 2. Header Guidance
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.devices_other_outlined, color: electricTeal.withValues(alpha: 0.2), size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              "AUTHORIZED DEVICES",
                              style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                            ),
                            const Text(
                              "Review and manage your active digital identity sessions.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Dynamic Session Ledger
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: sessionsQuery.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildSessionCard(docs[index]),
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),

                    // 4. Danger Zone
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildPurgeButton(user),
                      ),
                    ),
                    
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
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text("SESSION LEDGER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildSessionCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final device = (data['device'] ?? 'Authorized Identity').toString();
    final ip = (data['ipAddress'] ?? 'Hidden Mask').toString();
    final ts = data['lastActive'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: electricTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phonelink_lock_outlined, color: electricTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(ts != null ? "Active ${timeago.format(ts.toDate())}" : "Logged", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                Text("IP: $ip", style: const TextStyle(color: Colors.white12, fontSize: 10)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _terminateSession(doc.reference),
            child: const Text("REVOKE", style: TextStyle(color: errorRed, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPurgeButton(User user) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.security_update_warning_outlined, size: 20),
        label: const Text("TERMINATE ALL SESSIONS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        onPressed: () => _terminateAllSessions(user),
        style: OutlinedButton.styleFrom(
          foregroundColor: errorRed,
          side: const BorderSide(color: errorRed, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("No active sessions recorded.", style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontWeight: FontWeight.bold)),
      ),
    );
  }
}
