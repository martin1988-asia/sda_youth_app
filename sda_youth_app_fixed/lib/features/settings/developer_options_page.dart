import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({super.key});

  @override
  State<DeveloperOptionsPage> createState() => _DeveloperOptionsPageState();
}

class _DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  bool _debugMode = false;
  bool _betaOptIn = false;

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
        _debugMode = data['debugMode'] ?? false;
        _betaOptIn = data['betaOptIn'] ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'debugMode': _debugMode,
      'betaOptIn': _betaOptIn,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Developer options saved")),
    );
  }

  Future<void> _exportLogs() async {
    // Placeholder for actual log export logic
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logs exported successfully")),
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
                      title: const Text("Developer Options"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Enable Debug Mode"),
                      subtitle: const Text("Show extra logs and developer info"),
                      value: _debugMode,
                      onChanged: (val) => setState(() => _debugMode = val),
                    ),
                    SwitchListTile(
                      title: const Text("Beta Features Opt-in"),
                      subtitle: const Text("Try experimental features before release"),
                      value: _betaOptIn,
                      onChanged: (val) => setState(() => _betaOptIn = val),
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text("Export Logs"),
                      subtitle: const Text("Download app logs for debugging"),
                      onTap: _exportLogs,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Options"),
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
