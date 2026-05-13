// lib/features/settings/privacy_data_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Privacy & Data Sector — High-fidelity Identity Control for SDA Youth.
class PrivacyDataPage extends StatefulWidget {
  const PrivacyDataPage({super.key});

  @override
  State<PrivacyDataPage> createState() => _PrivacyDataPageState();
}

class _PrivacyDataPageState extends State<PrivacyDataPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  bool _shareDataEnabled = true;
  bool _analyticsEnabled = true;
  bool _personalizedAdsEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc(user.uid).get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _shareDataEnabled = data['shareDataEnabled'] ?? true;
          _analyticsEnabled = data['analyticsEnabled'] ?? true;
          _personalizedAdsEnabled = data['personalizedAdsEnabled'] ?? false;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commitPrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
        'shareDataEnabled': _shareDataEnabled,
        'analyticsEnabled': _analyticsEnabled,
        'personalizedAdsEnabled': _personalizedAdsEnabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Privacy Ledger Synchronized");
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purgeHistory(bool deleteAll) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await _showConfirmDialog(deleteAll);
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Purge Posts
      final posts = await FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: user.uid).get();
      for (var doc in posts.docs) { batch.delete(doc.reference); }

      // Purge Feedback
      final feedback = await FirebaseFirestore.instance.collection('feedback').where('userId', isEqualTo: user.uid).get();
      for (var doc in feedback.docs) { batch.delete(doc.reference); }

      await batch.commit();
      if (mounted) {
        setState(() => _loading = false);
        _showFeedback(deleteAll ? "All Identity Data Purged" : "History Cleared");
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

  Future<bool?> _showConfirmDialog(bool isFullDelete) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(isFullDelete ? "PURGE ALL DATA?" : "CLEAR HISTORY?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          isFullDelete 
            ? "This action is irreversible. All your community contributions and metadata will be permanently erased." 
            : "Remove your post and feedback history from the public ledger?",
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("CONFIRM"),
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
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: electricTeal))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildSector("Intelligence Sharing", [
                                _switchTile("Anonymized Sharing", "Improve the community experience", _shareDataEnabled, (v) => setState(() => _shareDataEnabled = v)),
                                _switchTile("Usage Analytics", "Help us measure mission impact", _analyticsEnabled, (v) => setState(() => _analyticsEnabled = v)),
                                _switchTile("Relevant Content", "Personalized Bible & Event insights", _personalizedAdsEnabled, (v) => setState(() => _personalizedAdsEnabled = v)),
                              ]),

                              _buildSector("Data Governance", [
                                _actionTile("Clear Activity Ledger", "Purge your post and feedback history", Icons.history, Colors.orangeAccent, () => _purgeHistory(false)),
                                _actionTile("Export Identity Data", "Request a portable copy of your record", Icons.download_for_offline_outlined, electricTeal, () {}),
                              ]),

                              _buildDangerZone(),

                              const SizedBox(height: 32),
                              _buildSaveButton(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
      title: const Text("PRIVACY VAULT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
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

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: errorRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: errorRed.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DANGER ZONE", style: TextStyle(color: errorRed, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          _actionTile("Purge Identity Record", "Permanently delete all community data", Icons.delete_forever_outlined, errorRed, () => _purgeHistory(true)),
        ],
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      value: value,
      activeThumbColor: electricTeal,
      activeTrackColor: electricTeal.withValues(alpha: 0.2),
      onChanged: onChanged,
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 24),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _loading ? null : _commitPrivacySettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          shadowColor: primaryTeal.withValues(alpha: 0.4),
        ),
        child: const Text("COMMIT PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
      ),
    );
  }
}
