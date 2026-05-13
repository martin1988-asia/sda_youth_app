// lib/features/settings/auth_security_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Security Vault Sector — High-fidelity Identity Protection for SDA Youth.
/// Manages multi-factor authentication, biometric identity, and key recovery.
class AuthSecurityPage extends StatefulWidget {
  const AuthSecurityPage({super.key});

  @override
  State<AuthSecurityPage> createState() => _AuthSecurityPageState();
}

class _AuthSecurityPageState extends State<AuthSecurityPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _loading = true;
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _loginAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityProtocols();
  }

  Future<void> _loadSecurityProtocols() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
          _biometricEnabled = data['biometricEnabled'] ?? false;
          _loginAlertsEnabled = data['loginAlertsEnabled'] ?? true;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commitSecuritySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .set({
        'twoFactorEnabled': _twoFactorEnabled,
        'biometricEnabled': _biometricEnabled,
        'loginAlertsEnabled': _loginAlertsEnabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Security Protocols Synchronized");
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Sync Error");
      }
    }
  }

  Future<void> _requestPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) _showFeedback("Reset Key Sent to Email");
    } catch (e) {
      if (mounted) _showFeedback("Transmission Failed");
    }
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: premiumBlack,
        body: Center(child: Text("Identity Verification Required", style: TextStyle(color: Colors.white38))),
      );
    }

    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
          // 1. Cinematic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: electricTeal))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAppBar(),
                        
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.verified_user_outlined, color: electricTeal.withValues(alpha: 0.2), size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "IDENTITY SECURITY",
                                  style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                                ),
                                const Text(
                                  "Manage your encryption keys and access protocols.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Control Sectors
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSector("Shield Protocols", [
                                  _switchTile("Two-Factor Auth", "Multi-step identity verification", _twoFactorEnabled, (v) => setState(() => _twoFactorEnabled = v)),
                                  _switchTile("Login Alerts", "Real-time notification of access", _loginAlertsEnabled, (v) => setState(() => _loginAlertsEnabled = v)),
                                ]),

                                _buildSector("Biometric Identity", [
                                  _switchTile("Fingerprint / Face", "Unlock identity via physical signature", _biometricEnabled, (v) => setState(() => _biometricEnabled = v)),
                                ]),

                                _buildSector("Recovery & Governance", [
                                  _actionTile("Reset Identity Key", "Transmit reset link to email", Icons.key_outlined, accentYellow, _requestPasswordReset),
                                  _actionTile("Session Management", "Audit authorized devices", Icons.devices_outlined, electricTeal, () => context.push('/session_management')),
                                ]),

                                const SizedBox(height: 32),
                                _buildSaveButton(),
                                const SizedBox(height: 100),
                              ],
                            ),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text("SECURITY VAULT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
    );
  }

  Widget _buildSector(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      value: value,
      activeThumbColor: electricTeal,
      activeTrackColor: electricTeal.withValues(alpha: 0.2),
      onChanged: onChanged,
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _loading ? null : _commitSecuritySettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          shadowColor: primaryTeal.withValues(alpha: 0.4),
        ),
        child: const Text("COMMIT PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
      ),
    );
  }
}
