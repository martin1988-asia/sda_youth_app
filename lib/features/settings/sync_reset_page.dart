// lib/features/settings/sync_reset_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Sync & Reset Sector — High-fidelity System Control for SDA Youth.
/// Manages local-to-cloud identity state and factory resets.
class SyncResetPage extends StatefulWidget {
  const SyncResetPage({super.key});

  @override
  State<SyncResetPage> createState() => _SyncResetPageState();
}

class _SyncResetPageState extends State<SyncResetPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  String? _lastSynced;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncLedger();
  }

  Future<void> _loadSyncLedger() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final value = data['lastSynced'];
        String? formatted;
        if (value is Timestamp) {
          formatted = value.toDate().toLocal().toString().split('.').first;
        }
        setState(() {
          _lastSynced = formatted;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSync() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .set(
        {'lastSynced': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      if (mounted) {
        final now = DateTime.now().toLocal().toString().split('.').first;
        setState(() {
          _lastSynced = now;
          _loading = false;
        });
        _showFeedback("Identity Synchronized with Cloud");
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .delete();

      if (mounted) {
        setState(() {
          _lastSynced = null;
          _loading = false;
        });
        _showFeedback("System Preferences Restored to Default");
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("FACTORY RESET?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("This will erase your personalized app preferences. Your community profile and posts will not be affected.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("RESET"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: electricTeal))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAppBar(),
                        
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.sync_problem_outlined, color: accentYellow.withValues(alpha: 0.2), size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "IDENTITY SYNCHRONIZATION",
                                  style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                                ),
                                const Text(
                                  "Manage the alignment between your local device and the mission cloud.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSector("Cloud Ledger", [
                                  _actionTile(
                                    "Synchronize Now", 
                                    _lastSynced != null ? "Last active: $_lastSynced" : "Manual sync required", 
                                    Icons.sync_rounded, 
                                    electricTeal, 
                                    _handleSync
                                  ),
                                ]),

                                _buildSector("System Maintenance", [
                                  _actionTile(
                                    "Reset Local Defaults", 
                                    "Restore factory settings without data loss", 
                                    Icons.settings_backup_restore_rounded, 
                                    Colors.orangeAccent, 
                                    _handleReset
                                  ),
                                ]),

                                const SizedBox(height: 100),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text("SYNC HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
    );
  }

  Widget _buildSector(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
      onTap: onTap,
    );
  }
}
