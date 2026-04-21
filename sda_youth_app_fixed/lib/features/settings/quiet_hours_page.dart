import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuietHoursPage extends StatefulWidget {
  const QuietHoursPage({super.key});

  @override
  State<QuietHoursPage> createState() => _QuietHoursPageState();
}

class _QuietHoursPageState extends State<QuietHoursPage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0); // default 10 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);   // default 7 AM
  bool _quietHoursEnabled = false;
  bool _suppressCalls = false;
  bool _suppressMessages = false;

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
        _quietHoursEnabled = data['quietHoursEnabled'] ?? false;
        _suppressCalls = data['suppressCalls'] ?? false;
        _suppressMessages = data['suppressMessages'] ?? false;

        final start = data['quietHoursStart']?.split(":");
        final end = data['quietHoursEnd']?.split(":");
        if (start != null && start.length == 2) {
          _startTime = TimeOfDay(
              hour: int.tryParse(start[0]) ?? 22,
              minute: int.tryParse(start[1]) ?? 0);
        }
        if (end != null && end.length == 2) {
          _endTime = TimeOfDay(
              hour: int.tryParse(end[0]) ?? 7,
              minute: int.tryParse(end[1]) ?? 0);
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'quietHoursEnabled': _quietHoursEnabled,
      'quietHoursStart': "${_startTime.hour}:${_startTime.minute}",
      'quietHoursEnd': "${_endTime.hour}:${_endTime.minute}",
      'suppressCalls': _suppressCalls,
      'suppressMessages': _suppressMessages,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Quiet hours settings saved")),
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (!mounted) return;
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (!mounted) return;
    if (picked != null) setState(() => _endTime = picked);
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
                      title: const Text("Quiet Hours / Do Not Disturb"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Enable Quiet Hours"),
                      value: _quietHoursEnabled,
                      onChanged: (val) => setState(() => _quietHoursEnabled = val),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.nightlight),
                      title: const Text("Start Time"),
                      subtitle: Text(_startTime.format(context)),
                      onTap: _pickStartTime,
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny),
                      title: const Text("End Time"),
                      subtitle: Text(_endTime.format(context)),
                      onTap: _pickEndTime,
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text("Suppress During Quiet Hours",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SwitchListTile(
                      title: const Text("Suppress Calls"),
                      value: _suppressCalls,
                      onChanged: (val) => setState(() => _suppressCalls = val),
                    ),
                    SwitchListTile(
                      title: const Text("Suppress Messages"),
                      value: _suppressMessages,
                      onChanged: (val) => setState(() => _suppressMessages = val),
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
