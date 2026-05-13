// lib/features/auth/signup_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Signup Sector — World-Class Onboarding & Identity Creation.
/// Initializes the "Titan Identity" across Auth, User Ledger, and Discovery ledgers.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC); 
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumWhite = Color(0xFFFFFFFF);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _churchPositionController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  // Selection States
  String? _selectedRegion;
  String? _selectedSex;
  String? _selectedMaritalStatus;
  String? _selectedLanguage;
  String? _selectedConference;
  String? _selectedChurch;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  // Data Constants
  final List<String> regions = const ['Erongo', 'Khomas', 'Oshana', 'Ohangwena', 'Omusati', 'Oshikoto', 'Kavango East', 'Kavango West', 'Zambezi', 'Kunene', 'Otjozondjupa', 'Omaheke', 'Hardap', '//Karas'];
  final List<String> conferences = const ['Southern Conference', 'Northern Conference'];
  final List<String> languages = const ['English', 'Afrikaans', 'Oshiwambo', 'Damara/Nama', 'Herero', 'Other'];
  final List<String> sexes = const ['Male', 'Female', 'Prefer not to say'];
  final List<String> maritalStatuses = const ['Single', 'Married', 'Divorced', 'Widowed'];
  
  final Map<String, List<String>> churchesByRegion = const {
    'Erongo': ['Walvis Bay SDA', 'Kuisebmund SDA', 'Swakopmund SDA'],
    'Khomas': ['Windhoek Central SDA', 'Katutura SDA', 'Hakahana SDA', 'Eros SDA', 'Bethesda SDA'],
    'Oshana': ['Oshakati SDA', 'Ondangwa SDA', 'Etunda SDA'],
    'Zambezi': ['Katima Mulilo SDA', 'Choto SDA', 'Bukalo SDA', 'Chinchimane SDA'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _churchPositionController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showFeedback("Please accept the community guidelines.", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();

      // 1. Initialize Auth Identity
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (cred.user != null) {
        final uid = cred.user!.uid;
        
        // Synchronize display name for Auth system immediately
        await cred.user!.updateDisplayName(name);

        final interests = _interestsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final batch = FirebaseFirestore.instance.batch();

        // 2. Register Discovery Lookup (Strict email-to-UID mapping)
        final lookupRef = FirebaseFirestore.instance.collection('user_lookup').doc(uid);
        batch.set(lookupRef, {
          'uid': uid,
          'displayName': name,
          'usernameLower': username.toLowerCase(),
          'emailLower': email,
          'region': _selectedRegion,
          'church': _selectedChurch,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Populate Main Identity Ledger
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        batch.set(userRef, {
          'uid': uid,
          'email': email,
          'name': name,
          'username': username,
          'age': int.tryParse(_ageController.text),
          'sex': _selectedSex,
          'maritalStatus': _selectedMaritalStatus,
          'language': _selectedLanguage,
          'region': _selectedRegion,
          'conference': _selectedConference,
          'church': _selectedChurch,
          'churchPosition': _churchPositionController.text.trim(),
          'bio': _bioController.text.trim(),
          'interests': interests,
          'role': 'user',
          'status': 'active',
          'profileVisible': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (mounted) context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      _showFeedback(e.message ?? "Registration Error", isError: true);
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      _showFeedback("Identity initialization failed.", isError: true);
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Hero(tag: 'app_logo', child: Image.asset('assets/sda_logo.png', height: 80)),
                        const SizedBox(height: 12),
                        const Text("CREATE IDENTITY", style: TextStyle(color: accentYellow, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
                        const Text("Strict Security • Kingdom Focused", style: TextStyle(color: electricTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 40),

                        _buildSection("Account Security", [
                          _buildField(_emailController, "EMAIL ADDRESS", Icons.alternate_email, required: true, type: TextInputType.emailAddress),
                          _buildField(_passwordController, "CREATE SECURE PASSWORD", Icons.lock_outline, required: true, isPassword: true),
                          _buildField(
                            _confirmPasswordController, 
                            "CONFIRM SECURE PASSWORD", 
                            Icons.shield_outlined, 
                            required: true, 
                            isPassword: true,
                            validator: (v) => v != _passwordController.text ? "Passwords do not match" : null,
                          ),
                        ]),

                        _buildSection("Personal Identity", [
                          _buildField(_nameController, "FULL NAME", Icons.person_outline, required: true),
                          _buildField(_usernameController, "PUBLIC @USERNAME", Icons.fingerprint, required: true),
                          Row(
                            children: [
                              Expanded(child: _buildField(_ageController, "AGE", Icons.cake_outlined, required: true, type: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDropdown("SEX", sexes, _selectedSex, (v) => setState(() => _selectedSex = v), required: true)),
                            ],
                          ),
                          _buildDropdown("MARITAL STATUS", maritalStatuses, _selectedMaritalStatus, (v) => setState(() => _selectedMaritalStatus = v), required: true),
                          _buildDropdown("PRIMARY LANGUAGE", languages, _selectedLanguage, (v) => setState(() => _selectedLanguage = v), required: true),
                          _buildField(_bioController, "SHORT BIOGRAPHY", Icons.notes, maxLines: 2),
                          _buildField(_interestsController, "INTERESTS (COMMA SEPARATED)", Icons.auto_awesome),
                        ]),

                        _buildSection("Church Connection", [
                          _buildDropdown("REGION", regions, _selectedRegion, (v) => setState(() { _selectedRegion = v; _selectedChurch = null; }), required: true),
                          _buildDropdown("CONFERENCE", conferences, _selectedConference, (v) => setState(() => _selectedConference = v), required: true),
                          _buildDropdown("LOCAL CHURCH", churchesByRegion[_selectedRegion] ?? [], _selectedChurch, (v) => setState(() => _selectedChurch = v), required: true),
                          _buildField(_churchPositionController, "YOUR SERVICE POSITION", Icons.military_tech),
                        ]),

                        CheckboxListTile(
                          title: const Text(
                            "I accept the Community Covenant and Guidelines",
                            style: TextStyle(color: electricTeal, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          value: _acceptTerms,
                          activeColor: electricTeal,
                          checkColor: Colors.black,
                          onChanged: (v) => setState(() => _acceptTerms = v!),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),

                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: electricTeal, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool required = false, bool isPassword = false, TextInputType type = TextInputType.text, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(color: premiumWhite, fontWeight: FontWeight.bold),
        validator: validator ?? (v) => required && (v == null || v.isEmpty) ? "Field Required" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
          floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, color: primaryTeal, size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
          filled: true,
          fillColor: Colors.black45,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 2)),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged, {bool required = false}) {
    final safeValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        dropdownColor: const Color(0xff0e1a2b),
        style: const TextStyle(color: premiumWhite, fontWeight: FontWeight.bold),
        validator: (v) => required && (v == null || v.isEmpty) ? "Field Required" : null,
        items: items.toSet().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2),
          floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
          prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, color: primaryTeal, size: 20),
          filled: true,
          fillColor: Colors.black45,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 2)),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          shadowColor: primaryTeal.withValues(alpha: 0.6),
        ),
        child: _loading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("INITIALIZE ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3)),
      ),
    );
  }
}

