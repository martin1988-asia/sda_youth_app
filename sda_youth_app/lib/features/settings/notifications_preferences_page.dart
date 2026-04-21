import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPreferencesPage extends StatefulWidget {
  const NotificationsPreferencesPage({super.key});

  @override
  State<NotificationsPreferencesPage> createState() =>
      _NotificationsPreferencesPageState();
}

class _NotificationsPreferencesPageState
    extends State<NotificationsPreferencesPage> {
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

    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _communityUpdates = data['communityUpdates'] ?? true;
        _devotionalsUpdates = data['devotionalsUpdates'] ?? true;
        _matchmakingUpdates = data['matchmakingUpdates'] ?? true;
        _soundEnabled = data['soundEnabled'] ?? true;
        _vibrationEnabled = data['vibrationEnabled'] ?? true;
        _emailNotifications = data['emailNotifications'] ?? true;
        _pushNotifications = data['pushNotifications'] ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification preferences saved")),
    );
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
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    AppBar(
                      title: const Text("Notification Preferences"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      title: Text(
                        "Customize Notifications",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text("Community Updates"),
                      value: _communityUpdates,
                      onChanged: (val) => setState(() => _communityUpdates = val),
                    ),
                    SwitchListTile(
                      title: const Text("Daily Devotionals"),
                      value: _devotionalsUpdates,
                      onChanged: (val) => setState(() => _devotionalsUpdates = val),
                    ),
                    SwitchListTile(
                      title: const Text("Matchmaking Suggestions"),
                      value: _matchmakingUpdates,
                      onChanged: (val) => setState(() => _matchmakingUpdates = val),
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text(
                        "Delivery Channels",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text("Email Notifications"),
                      value: _emailNotifications,
                      onChanged: (val) => setState(() => _emailNotifications = val),
                    ),
                    SwitchListTile(
                      title: const Text("Push Notifications"),
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text(
                        "Sound & Vibration",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text("Enable Sound"),
                      value: _soundEnabled,
                      onChanged: (val) => setState(() => _soundEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Enable Vibration"),
                      value: _vibrationEnabled,
                      onChanged: (val) => setState(() => _vibrationEnabled = val),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Preferences"),
                        onPressed: _saveSettings,
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
}
