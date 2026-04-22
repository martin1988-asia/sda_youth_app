import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacyDataPage extends StatefulWidget {
  const PrivacyDataPage({super.key});

  @override
  State<PrivacyDataPage> createState() => _PrivacyDataPageState();
}

class _PrivacyDataPageState extends State<PrivacyDataPage> {
  bool _shareDataEnabled = true;
  bool _analyticsEnabled = true;
  bool _personalizedAdsEnabled = false;

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
        _shareDataEnabled = data['shareDataEnabled'] ?? true;
        _analyticsEnabled = data['analyticsEnabled'] ?? true;
        _personalizedAdsEnabled = data['personalizedAdsEnabled'] ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'shareDataEnabled': _shareDataEnabled,
      'analyticsEnabled': _analyticsEnabled,
      'personalizedAdsEnabled': _personalizedAdsEnabled,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Privacy & Data settings saved")),
    );
  }

  Future<void> _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final posts = await FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: user.uid)
        .get();
    for (var doc in posts.docs) {
      await doc.reference.delete();
    }

    final feedback = await FirebaseFirestore.instance
        .collection('feedback')
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in feedback.docs) {
      await doc.reference.delete();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("History cleared successfully")),
    );
  }

  Future<void> _exportData() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data export feature coming soon")),
    );
  }

  Future<void> _deleteAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete All Data"),
        content: const Text(
            "Are you sure you want to permanently delete all your data? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      final collections = ['posts', 'feedback', 'devotionals'];
      for (var col in collections) {
        final docs = await FirebaseFirestore.instance
            .collection(col)
            .where('userId', isEqualTo: user.uid)
            .get();
        for (var doc in docs.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All data deleted successfully")),
      );
    }
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
                      title: const Text("Privacy & Data"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      title: Text("Privacy Preferences",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SwitchListTile(
                      title: const Text("Allow Data Sharing"),
                      value: _shareDataEnabled,
                      onChanged: (val) => setState(() => _shareDataEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Enable Analytics"),
                      value: _analyticsEnabled,
                      onChanged: (val) => setState(() => _analyticsEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Personalized Ads"),
                      value: _personalizedAdsEnabled,
                      onChanged: (val) => setState(() => _personalizedAdsEnabled = val),
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text("Manage Data",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text("Clear History"),
                      onTap: _clearHistory,
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text("Export My Data"),
                      onTap: _exportData,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text("Delete All Data"),
                      onTap: _deleteAllData,
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
