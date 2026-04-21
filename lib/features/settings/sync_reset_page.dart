import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SyncResetPage extends StatefulWidget {
  const SyncResetPage({super.key});

  @override
  State<SyncResetPage> createState() => _SyncResetPageState();
}

class _SyncResetPageState extends State<SyncResetPage> {
  String? _lastSynced;

  Future<void> _syncNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'lastSynced': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => _lastSynced = DateTime.now().toIso8601String());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data synced successfully")),
    );
  }

  Future<void> _resetData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Reset"),
        content: const Text(
          "This will erase all your settings and data. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reset"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App data reset successfully")),
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
                      title: const Text("Sync & Reset"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text("Sync Now"),
                      subtitle: Text(
                        _lastSynced != null
                            ? "Last synced: $_lastSynced"
                            : "Never synced",
                      ),
                      onTap: _syncNow,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text("Reset App Data"),
                      subtitle: const Text("Erase all settings and start fresh"),
                      onTap: _resetData,
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
