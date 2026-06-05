// ✅ FINAL FULL VERSION — STRUCTURED, RICH, PREMIUM

import 'dart:ui';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage>
    with SingleTickerProviderStateMixin {
  // ✅ CONSISTENT COLORS (APP-WIDE)
  static const primary = Color(0xFF008080);
  static const accent = Color(0xFF00FFCC);
  static const bg = Color(0xFF050505);
  static const surface = Color(0xFF111111);
  static const error = Color(0xFFFF3333);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();

  File? _avatar;

  bool _loading = false;
  bool _pressed = false;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    _email.text = user?.email ?? '';
    _name.text = user?.displayName ?? '';

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    _slide = Tween<double>(begin: 20, end: 0).animate(_fade);

    _anim.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _pass.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ✅ IMAGE PICKER
  Future<void> _pickImage() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    if (result != null) {
      setState(() => _avatar = File(result.path));
    }
  }

  // ✅ FEEDBACK
  void _toast(String msg, {bool err = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: err ? error : primary),
    );
  }

  // ✅ LOGIC (UNCHANGED)

  Future<void> _updateName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final name = _name.text.trim();

      await user.updateDisplayName(name);

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {'name': name},
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;
      _toast("Updated ✅");
    } catch (_) {
      if (!mounted) return;
      _toast("Failed ❌", err: true);
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _updateEmail() async {
    if (!_email.text.contains("@")) {
      _toast("Invalid email", err: true);
      return;
    }

    await FirebaseAuth.instance.currentUser!.verifyBeforeUpdateEmail(
      _email.text,
    );

    if (!mounted) return;
    _toast("Verification sent 📩");
  }

  Future<void> _updatePass() async {
    if (_pass.text.length < 8) {
      _toast("Min 8 characters", err: true);
      return;
    }

    await FirebaseAuth.instance.currentUser!.updatePassword(_pass.text);

    if (!mounted) return;
    _toast("Password updated 🔒");
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete account?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: error),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    await FirebaseAuth.instance.currentUser!.delete();

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              // ✅ SUBTLE GRADIENT BACKGROUND (DEPTH)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0e1a2b), bg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: CustomScrollView(
                        slivers: [
                          _appBar(),

                          // ✅ HEADER
                          SliverToBoxAdapter(
                            child: Transform.translate(
                              offset: Offset(0, _slide.value),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),

                                  GestureDetector(
                                    onTap: _pickImage,
                                    onTapDown: (_) =>
                                        setState(() => _pressed = true),
                                    onTapUp: (_) =>
                                        setState(() => _pressed = false),

                                    child: AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      scale: _pressed ? 0.95 : 1,
                                      child: CircleAvatar(
                                        radius: 42,
                                        backgroundColor: Colors.white12,
                                        backgroundImage: _avatar != null
                                            ? FileImage(_avatar!)
                                            : null,
                                        child: _avatar == null
                                            ? Text(
                                                (user?.displayName ?? "U")[0],
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    user?.email ?? "",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _section("Profile", [
                                      _field(_name, "Display Name"),
                                      _button("Update", _updateName),
                                    ]),

                                    _section("Email", [
                                      _field(_email, "Email"),
                                      _button("Verify", _updateEmail),
                                    ]),

                                    _section("Security", [
                                      _field(_pass, "Password", obscure: true),
                                      _button("Update", _updatePass),
                                    ]),

                                    _section("Danger Zone", [_deleteTile()]),

                                    const SizedBox(height: 100),
                                  ],
                                ),
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
        ),

        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // ✅ GLASS SECTION (LIKE ORIGINAL BUT MODERN)
  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        validator: (v) => v!.isEmpty ? "Required" : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: accent),
          filled: true,
          fillColor: Colors.black45,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback tap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _loading ? null : tap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _deleteTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _delete,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.delete, color: error),
              SizedBox(width: 10),
              Text("Delete Account", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text("PROFILE"),
    );
  }
}
