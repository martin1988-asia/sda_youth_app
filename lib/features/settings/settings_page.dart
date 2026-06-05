import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../core/user_settings.dart';
import '../../services/presence_service.dart';

class SettingsPage extends StatefulWidget {
  final void Function(bool)? onToggleDarkMode;

  const SettingsPage({super.key, this.onToggleDarkMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  static const Color accent = Color(0xFF00FFCC);

  UserSettings? _settings;
  bool _loading = true;
  bool _syncing = false;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    state == AppLifecycleState.resumed
        ? PresenceService.setOnline()
        : PresenceService.setOffline();
  }

  Future<void> _init() async {
    final local = await UserSettings.loadLocal();
    if (!mounted) return;

    setState(() {
      _settings = local;
      _loading = false;
    });
  }

  Future<void> _save(VoidCallback fn) async {
    if (_settings == null) return;

    fn();
    await _settings!.saveLocal();
    await _settings!.saveCloud();

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);

    final cloud = await UserSettings.loadCloud();

    if (!mounted) return;

    setState(() {
      _settings = cloud;
      _syncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Synced ✅")),
    );
  }

  Future<void> _logout() async {
    await PresenceService.setOffline();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    context.go('/login');
  }

  // ================== UI HELPERS ==================

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      activeThumbColor: accent,
    );
  }

  Widget _header() {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.2), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? "User",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? "",
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "View profile",
                    style: TextStyle(color: Colors.white30),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


// ================== BUILD ==================
@override
Widget build(BuildContext context) {
  if (_loading || _settings == null) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return Scaffold(
    backgroundColor: const Color(0xFF050505),
    appBar: AppBar(
      title: const Text("Settings"),
      backgroundColor: Colors.transparent,
    ),

    // ✅ ✅ CENTERED PROFESSIONAL LAYOUT
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [

            // ✅ HEADER
            _header(),

            const SizedBox(height: 8),

            // ================= ACCOUNT =================
            _section("Account"),
            _card([
              _tile(
                icon: Icons.person,
                title: "Edit Profile",
                onTap: () => context.push('/profile'),
              ),
              _tile(
                icon: Icons.lock,
                title: "Change Password",
              ),
            ]),

            // ================= PRIVACY =================
            _section("Privacy"),
            _card([
              _switchTile(
                title: "Private Account",
                value: _settings!.privateAccount,
                onChanged: (v) => _save(() => _settings!.privateAccount = v),
              ),
              _switchTile(
                title: "Allow Messages",
                value: _settings!.allowMessages,
                onChanged: (v) => _save(() => _settings!.allowMessages = v),
              ),
            ]),

            // ================= NOTIFICATIONS =================
            _section("Notifications"),
            _card([
              _switchTile(
                title: "Likes",
                value: _settings!.notifyLikes,
                onChanged: (v) => _save(() => _settings!.notifyLikes = v),
              ),
              _switchTile(
                title: "Comments",
                value: _settings!.notifyComments,
                onChanged: (v) => _save(() => _settings!.notifyComments = v),
              ),
              _switchTile(
                title: "Messages",
                value: _settings!.notifyMessages,
                onChanged: (v) => _save(() => _settings!.notifyMessages = v),
              ),
            ]),

            // ================= REELS =================
            _section("Reels"),
            _card([
              _switchTile(
                title: "Autoplay",
                value: _settings!.autoplay,
                onChanged: (v) => _save(() => _settings!.autoplay = v),
              ),
              _switchTile(
                title: "Mute by default",
                value: _settings!.muteByDefault,
                onChanged: (v) => _save(() => _settings!.muteByDefault = v),
              ),
            ]),

            // ================= SYSTEM =================
            _section("System"),
            _card([
              _switchTile(
                title: "Dark Mode",
                value: _settings!.darkModeEnabled,
                onChanged: (v) async {
                  await _save(() => _settings!.darkModeEnabled = v);
                  widget.onToggleDarkMode?.call(v);
                },
              ),
              _tile(
                icon: Icons.sync,
                title: _syncing ? "Syncing..." : "Sync with Cloud",
                onTap: _sync,
              ),
            ]),

            // ================= ACCOUNT ACTIONS =================
            _section("Account Actions"),
            _card([
              _tile(
                icon: Icons.logout,
                title: "Logout",
                color: Colors.redAccent,
                onTap: _logout,
              ),
            ]),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
}
