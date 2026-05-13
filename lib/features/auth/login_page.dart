// lib/features/auth/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sda_youth_app/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final AuthService? authService;
  const LoginPage({super.key, this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // High-Visibility Design Palette
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusPassword = FocusNode();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late final AuthService _authService;

  bool _rememberMe = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? FirebaseAuthService();
    if (!kIsWeb) _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusPassword.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (mounted) setState(() => _biometricAvailable = available);
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> _handleLogin(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await _authService.setSessionPersistence(_rememberMe);
      final cred = await _authService.authenticateEmail(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
      );

      if (cred.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', _rememberMe);
        if (!ctx.mounted) return;
        ctx.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (!ctx.mounted) return;
      _showFeedback(ctx, e.message ?? "Authentication failed", isError: true);
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      if (!ctx.mounted) return;
      _showFeedback(ctx, "Unexpected error. Please try again.", isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin(BuildContext ctx) async {
    setState(() => _loading = true);

    try {
      final cred = await _authService.authenticateGoogle();
      if (cred == null || cred.user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (!ctx.mounted) return;
      ctx.go('/home');
    } on FirebaseAuthException catch (e) {
      if (!ctx.mounted) return;
      _showFeedback(ctx, e.message ?? "Google Sign-In failed.", isError: true);
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      if (ctx.mounted) {
        _showFeedback(ctx, "Google Sign-In was not successful.", isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFeedback(BuildContext ctx, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: isError ? Colors.redAccent : accentYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Image.asset('assets/sda_logo.png', height: 110),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "SIGN IN",
                      style: TextStyle(
                        color: accentYellow,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const Text(
                      "Official SDA Youth Digital Identity",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildGlassForm(context),

                    const SizedBox(height: 30),

                    _buildSocialDock(context),

                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "New Member? ",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: "Join Now",
                              style: TextStyle(
                                color: electricTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
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

  Widget _buildGlassForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInputField(
              controller: _emailController,
              label: "EMAIL ADDRESS",
              icon: Icons.alternate_email,
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _passwordController,
              label: "IDENTITY KEY",
              icon: Icons.lock_outline,
              isPassword: true,
              focusNode: _focusPassword,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: primaryTeal,
                    side: const BorderSide(color: Colors.white24, width: 2),
                    onChanged: (v) => setState(() => _rememberMe = v!),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Remember Me",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/forgot_password'),
                  child: const Text(
                    "Reset Key?",
                    style: TextStyle(
                      color: accentYellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _handleLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: primaryTeal.withValues(alpha: 0.5),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ACCESS ACCOUNT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: type,
      focusNode: focusNode,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
        floatingLabelStyle: const TextStyle(
          color: accentYellow,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: primaryTeal),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white24,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accentYellow, width: 2),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Required Field" : null,
    );
  }

  Widget _buildSocialDock(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dockButton(
          icon: Icons.g_mobiledata,
          color: Colors.redAccent,
          onTap: () => _handleGoogleLogin(context),
        ),
        if (_biometricAvailable && !kIsWeb) ...[
          const SizedBox(width: 25),
          _dockButton(
            icon: Icons.fingerprint,
            color: electricTeal,
            onTap: () {
              // Placeholder: add biometric unlock flow here later
            },
          ),
        ],
      ],
    );
  }

  Widget _dockButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 38),
      ),
    );
  }
}
