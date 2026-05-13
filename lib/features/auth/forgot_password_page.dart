// lib/features/auth/forgot_password_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  
  // High-Visibility Branding Palette
  static const Color accentYellow = Color(0xFFFFCC00); // Golden Amber
  static const Color electricTeal = Color(0xFF00FFCC); // High Visibility Guidance
  static const Color primaryTeal = Color(0xFF008080);

  late final TabController _tabController;
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();
  final TextEditingController _backupCodeController = TextEditingController();
  
  bool _loading = false;
  String? _verificationId; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _securityAnswerController.dispose();
    _backupCodeController.dispose();
    super.dispose();
  }

  // --- 1. EMAIL RECOVERY ---
  Future<void> _sendEmailReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return _showFeedback("Email Required", isError: true);
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await FirebaseAnalytics.instance.logEvent(name: 'recovery_email_sent');
      if (mounted) {
        _showFeedback("Reset link transmitted to $email", isError: false);
        context.go('/login');
      }
    } catch (e) { 
      _showFeedback("Transmission failed: $e", isError: true); 
    } finally { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  // --- 2. SMS RECOVERY ---
  Future<void> _sendSmsOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return _showFeedback("Phone Required", isError: true);
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (cred) async => await FirebaseAuth.instance.signInWithCredential(cred),
        verificationFailed: (e) => _showFeedback(e.message ?? "SMS Failed", isError: true),
        codeSent: (id, resend) {
          setState(() { _verificationId = id; _loading = false; });
          _showFeedback("Secure OTP Sent to $phone");
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (e) { 
      _showFeedback("SMS Error: $e", isError: true); 
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- 3. FAITH CHECK (Security Questions) ---
  Future<void> _verifyFaithCheck() async {
    final answer = _securityAnswerController.text.trim();
    if (answer.isEmpty) return _showFeedback("Bible Verse Required", isError: true);
    setState(() => _loading = true);
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users')
          .where('securityAnswer', isEqualTo: answer.toLowerCase())
          .limit(1).get();
      
      if (userSnap.docs.isNotEmpty && mounted) {
        _showFeedback("Faith Verified. Redirecting to Reset...");
        context.push('/reset_password'); 
      } else { 
        _showFeedback("Identity Verification Failed", isError: true); 
      }
    } catch (e) { 
      _showFeedback("System Error: $e", isError: true); 
    } finally { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  // --- 4. BACKUP TOKEN ---
  Future<void> _verifyBackupToken() async {
    final code = _backupCodeController.text.trim();
    if (code.isEmpty) return _showFeedback("Identity Token Required", isError: true);
    setState(() => _loading = true);
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users')
          .where('backupToken', isEqualTo: code)
          .limit(1).get();
      if (userSnap.docs.isNotEmpty && mounted) {
        context.push('/reset_password');
      } else { 
        _showFeedback("Invalid Identity Token", isError: true); 
      }
    } catch (e) { 
      _showFeedback("Verification Error", isError: true); 
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
          title: const Text("RECOVERY HUB", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: electricTeal,
            labelColor: electricTeal,
            unselectedLabelColor: Colors.white30,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.email_outlined), text: "EMAIL"),
              Tab(icon: Icon(Icons.sms_outlined), text: "SMS"),
              Tab(icon: Icon(Icons.menu_book_outlined), text: "FAITH"),
              Tab(icon: Icon(Icons.key_outlined), text: "TOKEN"),
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
                _buildCard("EMAIL RECOVERY", "Reset link via digital transmission", _emailController, "REGISTERED EMAIL", Icons.email, "TRANSMIT LINK", _sendEmailReset),
                _buildSmsTab(),
                _buildCard("FAITH CHECK", "Verify with your secret Bible Verse", _securityAnswerController, "SECRET BIBLE VERSE", Icons.menu_book, "VERIFY FAITH", _verifyFaithCheck),
                _buildCard("BACKUP TOKEN", "Restore with your 16-digit key", _backupCodeController, "IDENTITY TOKEN", Icons.vpn_key, "RESTORE ACCESS", _verifyBackupToken),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String sub, TextEditingController ctrl, String label, IconData icon, String btn, VoidCallback action) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: electricTeal, size: 40),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: accentYellow, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _buildInputField(ctrl, label, Icons.shield_outlined),
            const SizedBox(height: 32),
            _actionButton(btn, action),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            const Icon(Icons.phonelink_ring_outlined, color: electricTeal, size: 40),
            const SizedBox(height: 16),
            const Text("SMS RECOVERY", style: TextStyle(color: accentYellow, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Text("Verify identity via encrypted SMS link", style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _buildInputField(_phoneController, "PHONE (+264...)", Icons.phone_iphone),
            if (_verificationId != null) ...[
              const SizedBox(height: 16),
              _buildInputField(_otpController, "6-DIGIT OTP CODE", Icons.lock_clock_outlined),
            ],
            const SizedBox(height: 32),
            _actionButton(_verificationId == null ? "SEND OTP" : "VERIFY CODE", _verificationId == null ? _sendSmsOtp : _verifyFaithCheck),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
        floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
        prefixIcon: Icon(icon, color: primaryTeal, size: 20),
        filled: true,
        fillColor: Colors.black45,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 2)),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback action) {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: _loading ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: primaryTeal.withValues(alpha: 0.4),
        ),
        child: _loading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }
}
