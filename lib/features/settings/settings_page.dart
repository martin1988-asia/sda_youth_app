import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/user_settings.dart';

// Import sub-pages
import 'accessibility_page.dart';
import 'notifications_preferences_page.dart';
import 'quiet_hours_page.dart';
import 'app_behavior_page.dart';
import 'auth_security_page.dart';
import '../profile/account_profile_page.dart';
import '../community/feedback_page.dart';
import '../community/community_page.dart';
import '../community/support_page.dart';
import '../community/about_page.dart';
import 'session_management_page.dart';

class SettingsPage extends StatefulWidget {
  final void Function(bool)? onToggleDarkMode;

  const SettingsPage({super.key, this.onToggleDarkMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();
    UserSettings.loadLocal().then((local) {
      if (mounted) setState(() => _settings = local);
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncNow() async {
    try {
      final cloud = await UserSettings.loadCloud();
      if (!mounted) return;
      setState(() => _settings = cloud);
      await _settings!.saveLocal();
      if (!mounted) return;
      _showSnack("Settings synced with cloud");
    } catch (e) {
      _showSnack("Failed to sync: $e");
    }
  }

  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Settings"),
        content: const Text("Are you sure you want to reset all settings to defaults?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Reset")),
        ],
      ),
    );

    if (confirm == true) {
      await _settings!.resetToDefaults();
      if (!mounted) return;
      setState(() {});
      _showSnack("Settings reset to defaults");
    }
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          SafeArea(
            child: StreamBuilder<UserSettings>(
              stream: UserSettings.streamMerged(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading settings: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("No settings found"));
                }

                _settings = snapshot.data ?? _settings;
                if (_settings == null) {
                  return const Center(child: Text("No settings found"));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    AppBar(
                      title: const Text("Settings"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),

                    // Account & Profile
                    const ListTile(title: Text("Account & Profile", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: const Text("Edit Profile"), leading: const Icon(Icons.person), onTap: () => Navigator.pushNamed(context, '/profile')),
                    ListTile(title: const Text("Change Email"), leading: const Icon(Icons.email), onTap: () => _navigate(context, const AccountProfilePage())),
                    ListTile(title: const Text("Change Password"), leading: const Icon(Icons.lock), onTap: () => _navigate(context, const AccountProfilePage())),
                    ListTile(title: const Text("Manage Linked Accounts"), leading: const Icon(Icons.link), onTap: () => _navigate(context, const AccountProfilePage())),
                    ListTile(
                      title: const Text("Logout"),
                      leading: const Icon(Icons.exit_to_app),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Confirm Logout"),
                            content: const Text("Are you sure you want to log out?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
                              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Logout")),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                    ),
                    ListTile(title: const Text("Delete Account"), leading: const Icon(Icons.delete), onTap: () => _navigate(context, const AccountProfilePage())),

                    const Divider(),

                    // Authentication & Security
                    const ListTile(title: Text("Authentication & Security", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: const Text("Manage Security Settings"), leading: const Icon(Icons.lock), onTap: () => _navigate(context, const AuthSecurityPage())),
                    ListTile(title: const Text("Session Management"), leading: const Icon(Icons.devices), onTap: () => _navigate(context, const SessionManagementPage())),

                    const Divider(),

                    // Notifications
                    const ListTile(title: Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold))),
                    SwitchListTile(
                      title: const Text("Enable Notifications"),
                      value: _settings!.notificationsEnabled,
                      onChanged: (val) async {
                        if (!mounted) return;
                        setState(() => _settings!.notificationsEnabled = val);
                        _settings!.lastUpdated = DateTime.now();
                        await _settings!.saveLocal();
                        if (!mounted) return;
                        await _settings!.saveCloud();
                        if (!mounted) return;
                        _showSnack(val ? "Notifications enabled" : "Notifications disabled");
                      },
                    ),
                    ListTile(title: const Text("Notification Preferences"), leading: const Icon(Icons.notifications), onTap: () => _navigate(context, const NotificationsPreferencesPage())),
                    ListTile(title: const Text("Quiet Hours / Do Not Disturb"), leading: const Icon(Icons.nightlight), onTap: () => _navigate(context, const QuietHoursPage())),

                    const Divider(),

                    // Appearance & Accessibility
                    const ListTile(title: Text("Appearance & Accessibility", style: TextStyle(fontWeight: FontWeight.bold))),
                    SwitchListTile(
                      title: const Text("Dark Mode"),
                      value: _settings!.darkModeEnabled,
                      onChanged: (val) async {
                        if (!mounted) return;
                        setState(() => _settings!.darkModeEnabled = val);
                        _settings!.lastUpdated = DateTime.now();
                        await _settings!.saveLocal();
                        if (!mounted) return;
                        await _settings!.saveCloud();
                        if (!mounted) return;
                        widget.onToggleDarkMode?.call(val);
                      },
                    ),
                    ListTile(title: const Text("Accessibility"), leading: const Icon(Icons.accessibility), onTap: () => _navigate(context, const AccessibilityPage())),

                    const Divider(),

                    // App Behavior
                    const ListTile(title: Text("App Behavior", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: const Text("App Behavior Settings"), leading: const Icon(Icons.tune), onTap: () => _navigate(context, const AppBehaviorPage())),
                    SwitchListTile(
                      title: const Text("Data Saving Mode"),
                      value: _settings!.dataSaverEnabled,
                      onChanged: (val) async {
                        if (!mounted) return;
                        setState(() => _settings!.dataSaverEnabled = val);
                        _settings!.lastUpdated = DateTime.now();
                        await _settings!.saveLocal();
                        if (!mounted) return;
                        await _settings!.saveCloud();
                        if (!mounted) return;
                        _showSnack(val ? "Data Saving Mode enabled" : "Data Saving Mode disabled");
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Background Refresh"),
                      value: _settings!.backgroundRefreshEnabled,
                      onChanged: (val) async {
                        if (!mounted) return;
                        setState(() => _settings!.backgroundRefreshEnabled = val);
                        _settings!.lastUpdated = DateTime.now();
                        await _settings!.saveLocal();
                        if (!mounted) return;
                        await _settings!.saveCloud();
                        if (!mounted) return;
                        _showSnack(val ? "Background Refresh enabled" : "Background Refresh disabled");
                      },
                    ),

                    const Divider(),

                    // Community & Feedback
                    const ListTile(title: Text("Community & Feedback", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: const Text("Community"), leading: const Icon(Icons.group), onTap: () => _navigate(context, const CommunityPage())),
                    ListTile(title: const Text("Feedback"), leading: const Icon(Icons.feedback), onTap: () => _navigate(context, const FeedbackPage())),

                    const Divider(),

                    // Support & About
                    const ListTile(title: Text("Support & About", style: TextStyle(fontWeight: FontWeight.bold))),
                    ListTile(title: const Text("Support"), leading: const Icon(Icons.support_agent), onTap: () => _navigate(context, const SupportPage())),
                    ListTile(title: const Text("About"), leading: const Icon(Icons.info), onTap: () => _navigate(context, const AboutPage())),

                    const Divider(),

                    // Sync & Reset
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text("Sync Now"),
                      subtitle: Text("Last synced: ${_settings!.lastUpdated.toLocal()}"),
                      onTap: _syncNow,
                    ),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text("Reset to Defaults"),
                      onTap: _resetDefaults,
                    ),

                    const Divider(),

                    // Advanced / Developer Options
                    const ListTile(
                      title: Text(
                        "Advanced / Developer Options",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ListTile(
                      title: const Text("Debug Mode"),
                      leading: const Icon(Icons.bug_report),
                      onTap: () => _showSnack("Debug mode toggled"),
                    ),
                    ListTile(
                      title: const Text("Export Logs"),
                      leading: const Icon(Icons.file_download),
                      onTap: () => _showSnack("Logs exported"),
                    ),
                    ListTile(
                      title: const Text("Beta Features Opt-in"),
                      leading: const Icon(Icons.science),
                      onTap: () => _showSnack("Beta features opt-in coming soon"),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

