// lib/features/auth/reset_password_page.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  
  // High-Visibility Branding Palette
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final TabController _tabController;

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_newPasswordController.text.trim());
        await FirebaseAnalytics.instance.logEvent(name: 'identity_key_updated');
        
        if (mounted) {
          _showFeedback("Identity Key Updated Successfully", isError: false);
          context.go('/login');
        }
      } else {
        _showFeedback("Session expired. Please re-authenticate.", isError: true);
      }
    } catch (e) {
      _showFeedback("Update failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? Colors.redAccent : accentYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text("RESET IDENTITY", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: electricTeal,
            labelColor: electricTeal,
            unselectedLabelColor: Colors.white30,
            tabs: const [
              Tab(icon: Icon(Icons.lock_reset_outlined), text: "KEY"),
              Tab(icon: Icon(Icons.sms_outlined), text: "SMS"),
              Tab(icon: Icon(Icons.menu_book_outlined), text: "FAITH"),
              Tab(icon: Icon(Icons.vpn_key_outlined), text: "TOKEN"),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
            TabBarView(
              controller: _tabController,
              children: [
                _buildMainResetTab(),
                _buildComingSoonTab("SMS Verification Integration", Icons.phonelink_ring_outlined),
                _buildComingSoonTab("Faith-Verse Identity Verification", Icons.auto_stories_outlined),
                _buildComingSoonTab("Master Token Restore Integration", Icons.token_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainResetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.security, color: electricTeal, size: 48),
                const SizedBox(height: 16),
                const Text("SECURE NEW KEY", style: TextStyle(color: accentYellow, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const Text("Ensure your new key is strong and unique", style: TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                _buildInputField(
                  controller: _newPasswordController, 
                  label: "NEW IDENTITY KEY", 
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) => !_isPasswordStrong(v ?? '') ? "Use 8+ chars, 1 Cap, 1 Number" : null,
                ),
                const SizedBox(height: 18),
                _buildInputField(
                  controller: _confirmPasswordController, 
                  label: "CONFIRM NEW KEY", 
                  icon: Icons.shield_outlined,
                  isPassword: true,
                  validator: (v) => v != _newPasswordController.text ? "Keys do not match" : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handlePasswordReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: _loading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("UPDATE IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonTab(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white10, size: 80),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false, 
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
        floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
        prefixIcon: Icon(icon, color: primaryTeal),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white24),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: Colors.black45,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 2)),
      ),
    );
  }
}
