// lib/features/settings/accessibility_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Accessibility Sector — High-fidelity Inclusive Design for SDA Youth.
/// Manages the visual atmosphere, haptic feedback engine, and typography scaling.
class AccessibilityPage extends StatefulWidget {
  const AccessibilityPage({super.key});

  @override
  State<AccessibilityPage> createState() => _AccessibilityPageState();
}

class _AccessibilityPageState extends State<AccessibilityPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _darkModeEnabled = true;
  bool _highContrastEnabled = false;
  bool _reduceMotionEnabled = false;
  double _fontSize = 16.0;
  String _selectedLanguage = "English";
  bool _loading = true;

  final List<String> languages = const [
    "English", "Afrikaans", "Oshiwambo", "Damara/Nama", "Herero", "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadInclusionSettings();
  }

  Future<void> _loadInclusionSettings() async {
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
          _darkModeEnabled = data['darkModeEnabled'] ?? true;
          _highContrastEnabled = data['highContrastEnabled'] ?? false;
          _reduceMotionEnabled = data['reduceMotionEnabled'] ?? false;
          _fontSize = (data['fontSize'] ?? 16).toDouble();
          _selectedLanguage = data['language'] ?? "English";
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commitInclusionSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .set({
        'darkModeEnabled': _darkModeEnabled,
        'highContrastEnabled': _highContrastEnabled,
        'reduceMotionEnabled': _reduceMotionEnabled,
        'fontSize': _fontSize,
        'language': _selectedLanguage,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Inclusive Preferences Synchronized");
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Sync Error");
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
                        
                        // 2. High-Fidelity Live Preview
                        SliverToBoxAdapter(child: _buildLivePreview()),

                        // 3. Inclusion Control Hub
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSector("Visual Atmosphere", [
                                  _switchTile("Dark Mode Protocol", "Reduce identity eye strain", _darkModeEnabled, (v) => setState(() => _darkModeEnabled = v)),
                                  _switchTile("High Contrast Mode", "Enforce peak detail visibility", _highContrastEnabled, (v) => setState(() => _highContrastEnabled = v)),
                                  _switchTile("Reduce Motion", "Minimize cinematic transitions", _reduceMotionEnabled, (v) => setState(() => _reduceMotionEnabled = v)),
                                ]),

                                _buildSector("Typography Engine", [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Global Font Scaling", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                        const Text("Adjust the readability of the Word", style: TextStyle(color: Colors.white38, fontSize: 11)),
                                        const SizedBox(height: 12),
                                        Slider(
                                          min: 12,
                                          max: 24,
                                          divisions: 6,
                                          value: _fontSize,
                                          activeColor: electricTeal,
                                          inactiveColor: Colors.white10,
                                          label: "${_fontSize.toInt()}px",
                                          onChanged: (val) => setState(() => _fontSize = val),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text("${_fontSize.toInt()} PX", style: const TextStyle(color: accentYellow, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]),

                                _buildSector("Linguistic Identity", [
                                  _dropdownTile("Platform Language", "Choose your community tongue", _selectedLanguage, (v) => setState(() => _selectedLanguage = v!)),
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
      title: const Text("INCLUSION HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Text("ATMOSPHERE PREVIEW", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          Text(
            "Empowering every member through an inclusive mission experience.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: _fontSize,
              fontWeight: _highContrastEnabled ? FontWeight.w900 : FontWeight.w500,
              height: 1.5,
              letterSpacing: _highContrastEnabled ? 0.5 : 0,
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 16),
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
          items: languages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
        onPressed: _loading ? null : _commitInclusionSettings,
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
