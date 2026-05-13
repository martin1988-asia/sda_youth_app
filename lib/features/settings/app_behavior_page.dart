// lib/features/settings/app_behavior_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// App Behavior Sector — High-fidelity UX Control for SDA Youth.
/// Manages the navigation engine and interaction intelligence of the app.
class AppBehaviorPage extends StatefulWidget {
  const AppBehaviorPage({super.key});

  @override
  State<AppBehaviorPage> createState() => _AppBehaviorPageState();
}

class _AppBehaviorPageState extends State<AppBehaviorPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _loading = true;
  bool _autoPlayMedia = false;
  bool _dataSaverEnabled = false;
  bool _backgroundRefreshEnabled = true;
  bool _showTipsEnabled = true;
  String _defaultHomeTab = "Home";

  @override
  void initState() {
    super.initState();
    _loadBehaviorSettings();
  }

  Future<void> _loadBehaviorSettings() async {
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
          _autoPlayMedia = data['autoPlayMedia'] ?? false;
          _dataSaverEnabled = data['dataSaverEnabled'] ?? false;
          _backgroundRefreshEnabled = data['backgroundRefreshEnabled'] ?? true;
          _showTipsEnabled = data['showTipsEnabled'] ?? true;
          _defaultHomeTab = data['defaultHomeTab'] ?? "Home";
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commitBehaviorSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
        'autoPlayMedia': _autoPlayMedia,
        'dataSaverEnabled': _dataSaverEnabled,
        'backgroundRefreshEnabled': _backgroundRefreshEnabled,
        'showTipsEnabled': _showTipsEnabled,
        'defaultHomeTab': _defaultHomeTab,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("UX Architecture Synchronized");
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
                                Icon(Icons.settings_input_component_outlined, color: electricTeal.withValues(alpha: 0.2), size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "BEHAVIOR ENGINE",
                                  style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                                ),
                                const Text(
                                  "Customize how your digital identity interacts with the platform.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Control Sectors
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSector("Navigation Hub", [
                                  _dropdownTile(
                                    "Default Entry Tab", 
                                    "Choose your primary landing sector", 
                                    _defaultHomeTab, 
                                    (v) => setState(() => _defaultHomeTab = v!)
                                  ),
                                ]),

                                _buildSector("Interaction Intelligence", [
                                  _switchTile("Auto-Play Media", "Automatic transmission of visual content", _autoPlayMedia, (v) => setState(() => _autoPlayMedia = v)),
                                  _switchTile("Data Saving Mode", "Optimized bandwidth consumption", _dataSaverEnabled, (v) => setState(() => _dataSaverEnabled = v)),
                                  _switchTile("Background Refresh", "Real-time sync when identity is idle", _backgroundRefreshEnabled, (v) => setState(() => _backgroundRefreshEnabled = v)),
                                  _switchTile("System Guidance", "Show tips and platform tutorials", _showTipsEnabled, (v) => setState(() => _showTipsEnabled = v)),
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
      title: const Text("APP BEHAVIOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
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
          const SizedBox(height: 20),
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

  Widget _dropdownTile(String title, String subtitle, String value, ValueChanged<String?> onChanged) {
    final List<String> options = ["Home", "Community", "Devotionals", "Favorites", "Settings"];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: const Color(0xff0e1a2b),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _loading ? null : _commitBehaviorSettings,
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
