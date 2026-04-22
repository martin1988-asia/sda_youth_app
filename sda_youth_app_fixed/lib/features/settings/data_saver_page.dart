import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataSaverPage extends StatefulWidget {
  const DataSaverPage({super.key});

  @override
  State<DataSaverPage> createState() => _DataSaverPageState();
}

class _DataSaverPageState extends State<DataSaverPage> {
  bool _limitMediaDownloads = true;
  bool _reduceSyncFrequency = true;
  bool _optimizeBandwidth = true;
  bool _lowQualityImages = false;
  bool _disableAutoPlayVideos = false;

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
        _limitMediaDownloads = data['limitMediaDownloads'] ?? true;
        _reduceSyncFrequency = data['reduceSyncFrequency'] ?? true;
        _optimizeBandwidth = data['optimizeBandwidth'] ?? true;
        _lowQualityImages = data['lowQualityImages'] ?? false;
        _disableAutoPlayVideos = data['disableAutoPlayVideos'] ?? false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'limitMediaDownloads': _limitMediaDownloads,
      'reduceSyncFrequency': _reduceSyncFrequency,
      'optimizeBandwidth': _optimizeBandwidth,
      'lowQualityImages': _lowQualityImages,
      'disableAutoPlayVideos': _disableAutoPlayVideos,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data Saver settings saved")),
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
                      title: const Text("Data Saver"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      title: Text("Data Saver Options",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SwitchListTile(
                      title: const Text("Limit Media Downloads"),
                      subtitle: const Text("Download images/videos only on Wi-Fi"),
                      value: _limitMediaDownloads,
                      onChanged: (val) => setState(() => _limitMediaDownloads = val),
                    ),
                    SwitchListTile(
                      title: const Text("Reduce Sync Frequency"),
                      subtitle: const Text("Sync data less often to save bandwidth"),
                      value: _reduceSyncFrequency,
                      onChanged: (val) => setState(() => _reduceSyncFrequency = val),
                    ),
                    SwitchListTile(
                      title: const Text("Optimize Bandwidth"),
                      subtitle: const Text("Compress data and reduce usage"),
                      value: _optimizeBandwidth,
                      onChanged: (val) => setState(() => _optimizeBandwidth = val),
                    ),
                    SwitchListTile(
                      title: const Text("Use Low Quality Images"),
                      subtitle: const Text("Load lower resolution images to save data"),
                      value: _lowQualityImages,
                      onChanged: (val) => setState(() => _lowQualityImages = val),
                    ),
                    SwitchListTile(
                      title: const Text("Disable Auto-Play Videos"),
                      subtitle: const Text("Prevent videos from auto-playing"),
                      value: _disableAutoPlayVideos,
                      onChanged: (val) => setState(() => _disableAutoPlayVideos = val),
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
