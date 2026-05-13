// lib/features/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:go_router/go_router.dart';

import '../../core/user_settings.dart';

/// Settings Hub — Premium Control Center for the SDA Youth Experience.
class SettingsPage extends StatefulWidget {
  final void Function(bool)? onToggleDarkMode;
  const SettingsPage({super.key, this.onToggleDarkMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // High-Visibility Design Palette
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  UserSettings? _settings;
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeHub();
  }

  Future<void> _initializeHub() async {
    try {
      final local = await UserSettings.loadLocal();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdTokenResult(true);
        if (mounted) {
          setState(() => _isAdmin = token.claims?['role'] == 'admin');
        }
      }

      if (mounted) {
        setState(() {
          _settings = local;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSync() async {
    try {
      final cloud = await UserSettings.loadCloud();
      if (!mounted) return;

      setState(() => _settings = cloud);

      // Notify user immediately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cloud Identity Synced"),
          backgroundColor: primaryTeal,
        ),
      );

      await _settings!.saveLocal();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sync Failed")),
        );
      }
    }
  }

  Future<void> _persistSetting(VoidCallback updater) async {
    try {
      if (_settings == null) return;
      updater();
      _settings!.lastUpdated = DateTime.now();
      await _settings!.saveLocal();
      await _settings!.saveCloud();
      if (mounted) setState(() {});
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  Future<void> _handleResetDefaults() async {
    if (_settings == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "RESET TO FACTORY DEFAULTS?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will reset your experience, privacy, and notification preferences.",
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("RESET"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _settings!.resetToDefaults(); // saves local + cloud inside
      if (!mounted) return;

      setState(() {});

      // Inform app-level theme controller
      widget.onToggleDarkMode?.call(_settings!.darkModeEnabled);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings reset to factory defaults."),
          backgroundColor: primaryTeal,
        ),
      );
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reset failed. Please try again."),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "TERMINATE SESSION?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to sign out of your digital identity?",
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("LOGOUT"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
          // Cinematic Background
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
                ? const Center(
                    child: CircularProgressIndicator(color: electricTeal),
                  )
                : CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildSector("Identity & Profile", [
                                _tile(Icons.person_outline, "Public Profile",
                                    "/profile"),
                                _tile(
                                  Icons.email_outlined,
                                  "Identity Metadata",
                                  "/account_profile",
                                ),
                                _tile(
                                  Icons.logout,
                                  "Terminate Session",
                                  null,
                                  isAction: true,
                                  onTap: _handleLogout,
                                ),
                              ]),
                              _buildSector("Security & Privacy", [
                                _tile(Icons.shield_outlined, "Key Management",
                                    "/auth_security"),
                                _tile(
                                  Icons.devices_outlined,
                                  "Authorized Devices",
                                  "/session_management",
                                ),
                                _tile(
                                  Icons.privacy_tip_outlined,
                                  "Privacy Ledger",
                                  "/privacy_data",
                                ),
                              ]),
                              _buildSector("Experience", [
                                _switch(
                                  "Visual Dark Mode",
                                  _settings!.darkModeEnabled,
                                  (v) async {
                                    await _persistSetting(
                                      () => _settings!.darkModeEnabled = v,
                                    );
                                    widget.onToggleDarkMode?.call(v);
                                  },
                                ),
                                _switch(
                                  "Identity Notifications",
                                  _settings!.notificationsEnabled,
                                  (v) => _persistSetting(
                                    () => _settings!.notificationsEnabled = v,
                                  ),
                                ),
                                _tile(
                                  Icons.accessibility_new,
                                  "Accessibility Options",
                                  "/accessibility",
                                ),
                              ]),
                              _buildSector("System Tools", [
                                _tile(
                                  Icons.sync,
                                  "Sync Cloud Identity",
                                  null,
                                  isAction: true,
                                  onTap: _handleSync,
                                  subtitle:
                                      "Last sync: ${_settings!.lastUpdated.toLocal()}",
                                ),
                                _tile(
                                  Icons.restore,
                                  "Reset Factory Defaults",
                                  null,
                                  isAction: true,
                                  onTap: _handleResetDefaults,
                                ),
                              ]),
                              if (_isAdmin)
                                _buildSector("Mission Control (Admin)", [
                                  _tile(
                                    Icons.admin_panel_settings_outlined,
                                    "Personnel Hub",
                                    "/manage_users",
                                    color: Colors.redAccent,
                                  ),
                                  _tile(
                                    Icons.gpp_maybe_outlined,
                                    "Security Queue",
                                    "/moderation",
                                    color: Colors.redAccent,
                                  ),
                                  _tile(
                                    Icons.analytics_outlined,
                                    "Kingdom Metrics",
                                    "/analytics",
                                    color: Colors.redAccent,
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
        onPressed: () => context.go('/home'),
      ),
      title: const Text(
        "COMMAND HUB",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildSector(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: accentYellow,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    String? route, {
    bool isAction = false,
    VoidCallback? onTap,
    String? subtitle,
    Color color = electricTeal,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 11,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white10,
        size: 14,
      ),
      onTap: isAction
          ? onTap
          : () {
              if (route != null) context.push(route);
            },
    );
  }

  Widget _switch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      activeThumbColor: electricTeal,
      activeTrackColor: electricTeal.withValues(alpha: 0.2),
      onChanged: onChanged,
    );
  }
}
