// lib/features/settings/data_saver_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Data Saver Sector — High-fidelity Performance Control for SDA Youth.
/// Manages bandwidth optimization and media consumption intelligence.
class DataSaverPage extends StatefulWidget {
  const DataSaverPage({super.key});

  @override
  State<DataSaverPage> createState() => _DataSaverPageState();
}

class _DataSaverPageState extends State<DataSaverPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _limitMediaDownloads = true;
  bool _reduceSyncFrequency = true;
  bool _optimizeBandwidth = true;
  bool _lowQualityImages = false;
  bool _disableAutoPlayVideos = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOptimizationSettings();
  }

  Future<void> _loadOptimizationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _limitMediaDownloads = data['limitMediaDownloads'] ?? true;
          _reduceSyncFrequency = data['reduceSyncFrequency'] ?? true;
          _optimizeBandwidth = data['optimizeBandwidth'] ?? true;
          _lowQualityImages = data['lowQualityImages'] ?? false;
          _disableAutoPlayVideos = data['disableAutoPlayVideos'] ?? false;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commitSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .set({
        'limitMediaDownloads': _limitMediaDownloads,
        'reduceSyncFrequency': _reduceSyncFrequency,
        'optimizeBandwidth': _optimizeBandwidth,
        'lowQualityImages': _lowQualityImages,
        'disableAutoPlayVideos': _disableAutoPlayVideos,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Network Optimization Synchronized");
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Sync Failed");
      }
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
                                Icon(Icons.data_usage_rounded, color: electricTeal.withValues(alpha: 0.2), size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "DATA SAVER HUB",
                                  style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                                ),
                                const Text(
                                  "Manage how your digital identity consumes community bandwidth.",
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
                                _buildSector("Network Intelligence", [
                                  _switchTile("Optimize Bandwidth", "Compress system data transfers", _optimizeBandwidth, (v) => setState(() => _optimizeBandwidth = v)),
                                  _switchTile("Reduce Sync Frequency", "Update cloud ledger less often", _reduceSyncFrequency, (v) => setState(() => _reduceSyncFrequency = v)),
                                ]),

                                _buildSector("Media Consumption", [
                                  _switchTile("Wi-Fi Only Downloads", "Limit media to high-speed networks", _limitMediaDownloads, (v) => setState(() => _limitMediaDownloads = v)),
                                  _switchTile("Efficient Resolution", "Use lower quality visual assets", _lowQualityImages, (v) => setState(() => _lowQualityImages = v)),
                                  _switchTile("Disable Auto-Play", "Prevent automatic video transmission", _disableAutoPlayVideos, (v) => setState(() => _disableAutoPlayVideos = v)),
                                ]),

                                const SizedBox(height: 32),
                                _buildSaveButton(),
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
      title: const Text("OPTIMIZATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _loading ? null : _commitSettings,
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
