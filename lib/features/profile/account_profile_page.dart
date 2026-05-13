// lib/features/profile/account_profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Account Profile Sector — High-fidelity Identity Management for SDA Youth.
/// Manages primary metadata, authentication keys, and digital persistence.
class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeIdentityData();
  }

  void _initializeIdentityData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _displayNameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    if (!_formKey.currentState!.validate()) return;
    final String newName = _displayNameController.text.trim();
    
    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Sync Auth Profile
        await user.updateDisplayName(newName);

        final batch = FirebaseFirestore.instance.batch();
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final lookupRef = FirebaseFirestore.instance.collection('user_lookup').doc(user.uid);

        // 2. Sync Global User Metadata
        batch.set(userRef, {
          'name': newName, 
          'displayName': newName, 
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        // 3. Sync Discovery Ledger
        batch.set(lookupRef, {
          'displayName': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();

        if (mounted) _showFeedback("Identity Synchronized Successfully");
      }
    } catch (e) {
      if (mounted) _showFeedback("Sync Interrupted", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _changeEmail() async {
    final String newEmail = _emailController.text.trim().toLowerCase();
    if (newEmail.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
        
        final batch = FirebaseFirestore.instance.batch();
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final lookupRef = FirebaseFirestore.instance.collection('user_lookup').doc(user.uid);

        batch.set(userRef, {'email': newEmail, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        batch.set(lookupRef, {'emailLower': newEmail, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

        await batch.commit();
        if (mounted) _showFeedback("Verification Signal Sent to $newEmail");
      }
    } catch (e) {
      if (mounted) _showFeedback("Transmission Error", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 8) {
      _showFeedback("Security key must be 8+ characters", isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        if (mounted) {
          _showFeedback("Security Key Recalibrated");
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) _showFeedback("Access Denied: Please re-authenticate", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _purgeIdentity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("TERMINATE IDENTITY?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("This action will permanently erase your community record and all contributions. This is irreversible.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("PURGE ALL"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final uid = user.uid;
          await FirebaseFirestore.instance.collection('user_lookup').doc(uid).delete();
          await FirebaseFirestore.instance.collection('users').doc(uid).delete();
          await user.delete();
          if (mounted) context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showFeedback("Session must be fresh. Please re-login to purge.", isError: true);
        }
      }
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? errorRed : electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildSector("Personal Metadata", [
                                _buildInputField(_displayNameController, "IDENTITY DISPLAY NAME", Icons.person_outline),
                                const SizedBox(height: 12),
                                _buildActionButton("UPDATE METADATA", _updateDisplayName),
                              ]),
                              _buildSector("System Credentials", [
                                _buildInputField(_emailController, "PRIMARY EMAIL ADDRESS", Icons.alternate_email, type: TextInputType.emailAddress),
                                const SizedBox(height: 12),
                                _buildActionButton("TRANSMIT VERIFICATION", _changeEmail),
                              ]),
                              _buildSector("Security Layer", [
                                _buildInputField(_passwordController, "NEW ENCRYPTION KEY", Icons.lock_person_outlined, isPassword: true),
                                const SizedBox(height: 12),
                                _buildActionButton("SYNCHRONIZE KEY", _changePassword),
                              ]),
                              _buildSector("Critical Protocol", [
                                _buildPurgeButton(),
                              ]),
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
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      title: const Text("IDENTITY GOVERNANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
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
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      validator: (v) => v!.isEmpty ? "Identity data required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
        floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
        prefixIcon: Icon(icon, color: primaryTeal, size: 20),
        filled: true,
        fillColor: Colors.black45,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 2)),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isProcessing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildPurgeButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorRed.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: _isProcessing ? null : _purgeIdentity,
        leading: const Icon(Icons.delete_forever_outlined, color: errorRed),
        title: const Text("TERMINATE IDENTITY RECORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        subtitle: const Text("Permanent data removal protocol", style: TextStyle(color: Colors.white24, fontSize: 10)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white12),
      ),
    );
  }
}
