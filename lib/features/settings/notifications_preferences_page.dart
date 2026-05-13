// lib/features/settings/notifications_preferences_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

/// Notification Preferences — Premium Alert Control Center for SDA Youth.
class NotificationsPreferencesPage extends StatefulWidget {
  const NotificationsPreferencesPage({super.key});

  @override
  State<NotificationsPreferencesPage> createState() =>
      _NotificationsPreferencesPageState();
}

class _NotificationsPreferencesPageState
    extends State<NotificationsPreferencesPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _loading = true;
  
  // Preference States
  bool _communityUpdates = true;
  bool _devotionalsUpdates = true;
  bool _matchmakingUpdates = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _communityUpdates = data['communityUpdates'] ?? true;
          _devotionalsUpdates = data['devotionalsUpdates'] ?? true;
          _matchmakingUpdates = data['matchmakingUpdates'] ?? true;
          _soundEnabled = data['soundEnabled'] ?? true;
          _vibrationEnabled = data['vibrationEnabled'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? true;
          _pushNotifications = data['pushNotifications'] ?? true;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
        'communityUpdates': _communityUpdates,
        'devotionalsUpdates': _devotionalsUpdates,
        'matchmakingUpdates': _matchmakingUpdates,
        'soundEnabled': _soundEnabled,
        'vibrationEnabled': _vibrationEnabled,
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAnalytics.instance.logEvent(name: "save_notification_prefs");

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Alert Architecture Synchronized"),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Return to settings hub
      }
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save preferences"), backgroundColor: Colors.redAccent),
        );
      }
    }
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
                              const SizedBox(height: 20),
                              
                              _buildSector("Content Intelligence", [
                                _switchTile("Community Updates", "Engagement, likes, and comments", _communityUpdates, (v) => setState(() => _communityUpdates = v)),
                                _switchTile("Daily Devotionals", "Morning and evening spiritual insights", _devotionalsUpdates, (v) => setState(() => _devotionalsUpdates = v)),
                                _switchTile("Matchmaking", "Identity connection suggestions", _matchmakingUpdates, (v) => setState(() => _matchmakingUpdates = v)),
                              ]),

                              _buildSector("Transmission Channels", [
                                _switchTile("Push Notifications", "Real-time system alerts", _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                                _switchTile("Email Reports", "Weekly community digests", _emailNotifications, (v) => setState(() => _emailNotifications = v)),
                              ]),

                              _buildSector("Haptic & Audio", [
                                _switchTile("Enable Sound", "Audible alert signals", _soundEnabled, (v) => setState(() => _soundEnabled = v)),
                                _switchTile("Enable Vibration", "Physical haptic feedback", _vibrationEnabled, (v) => setState(() => _vibrationEnabled = v)),
                              ]),

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
      title: const Text("ALERT HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
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
        onPressed: _loading ? null : _saveSettings,
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
