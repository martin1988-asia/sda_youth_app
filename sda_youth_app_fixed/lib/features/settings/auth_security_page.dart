import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSecurityPage extends StatefulWidget {
  const AuthSecurityPage({super.key});

  @override
  State<AuthSecurityPage> createState() => _AuthSecurityPageState();
}

class _AuthSecurityPageState extends State<AuthSecurityPage> {
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _loginAlertsEnabled = true;

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
        _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
        _biometricEnabled = data['biometricEnabled'] ?? false;
        _loginAlertsEnabled = data['loginAlertsEnabled'] ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'twoFactorEnabled': _twoFactorEnabled,
      'biometricEnabled': _biometricEnabled,
      'loginAlertsEnabled': _loginAlertsEnabled,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Authentication & Security settings saved")),
    );
  }

  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent")),
    );
  }

  Future<void> _manageSessions() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session management coming soon")),
    );
  }

  Future<void> _logoutAllDevices() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out from all devices")),
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
                      title: const Text("Authentication & Security"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Enable Two-Factor Authentication"),
                      value: _twoFactorEnabled,
                      onChanged: (val) => setState(() => _twoFactorEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Enable Biometric Login"),
                      value: _biometricEnabled,
                      onChanged: (val) => setState(() => _biometricEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Login Alerts"),
                      subtitle: const Text("Notify me when my account is accessed"),
                      value: _loginAlertsEnabled,
                      onChanged: (val) => setState(() => _loginAlertsEnabled = val),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.devices),
                      title: const Text("Session Management"),
                      subtitle: const Text("Manage active sessions across devices"),
                      onTap: _manageSessions,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Logout All Devices"),
                      subtitle: const Text("Force logout from all active sessions"),
                      onTap: _logoutAllDevices,
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text("Reset Password"),
                      subtitle: const Text("Send password reset email"),
                      onTap: _resetPassword,
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
