import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppBehaviorPage extends StatefulWidget {
  const AppBehaviorPage({super.key});

  @override
  State<AppBehaviorPage> createState() => _AppBehaviorPageState();
}

class _AppBehaviorPageState extends State<AppBehaviorPage> {
  bool _autoPlayMedia = false;
  bool _dataSaverEnabled = false;
  bool _backgroundRefreshEnabled = true;
  bool _showTipsEnabled = true;
  String _defaultHomeTab = "Home";

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
        _autoPlayMedia = data['autoPlayMedia'] ?? false;
        _dataSaverEnabled = data['dataSaverEnabled'] ?? false;
        _backgroundRefreshEnabled = data['backgroundRefreshEnabled'] ?? true;
        _showTipsEnabled = data['showTipsEnabled'] ?? true;
        _defaultHomeTab = data['defaultHomeTab'] ?? "Home";
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'autoPlayMedia': _autoPlayMedia,
      'dataSaverEnabled': _dataSaverEnabled,
      'backgroundRefreshEnabled': _backgroundRefreshEnabled,
      'showTipsEnabled': _showTipsEnabled,
      'defaultHomeTab': _defaultHomeTab,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("App behavior settings saved")),
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
                      title: const Text("App Behavior"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      title: Text("Default Home Tab",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DropdownButtonFormField<String>(
                      value: _defaultHomeTab,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Choose default tab",
                      ),
                      items: const [
                        DropdownMenuItem(value: "Home", child: Text("Home")),
                        DropdownMenuItem(value: "Community", child: Text("Community")),
                        DropdownMenuItem(value: "Devotionals", child: Text("Devotionals")),
                        DropdownMenuItem(value: "Favorites", child: Text("Favorites")),
                        DropdownMenuItem(value: "Settings", child: Text("Settings")),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultHomeTab = val);
                      },
                      validator: (val) =>
                          val == null ? "Please select a default tab" : null,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Auto-play Media"),
                      value: _autoPlayMedia,
                      onChanged: (val) => setState(() => _autoPlayMedia = val),
                    ),
                    SwitchListTile(
                      title: const Text("Data Saving Mode"),
                      value: _dataSaverEnabled,
                      onChanged: (val) => setState(() => _dataSaverEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Background Refresh"),
                      value: _backgroundRefreshEnabled,
                      onChanged: (val) => setState(() => _backgroundRefreshEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Show Tips & Tutorials"),
                      value: _showTipsEnabled,
                      onChanged: (val) => setState(() => _showTipsEnabled = val),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Settings"),
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
