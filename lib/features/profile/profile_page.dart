// lib/features/profile/profile_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Profile Sector — World-Class Identity & Governance Hub for SDA Youth.
/// Manages synchronized digital identities across Auth and Firestore ledgers.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _churchPositionController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  // State Variables
  String? _selectedRegion;
  String? _selectedConference;
  String? _selectedLanguage;
  String? _selectedSex;
  String? _selectedMaritalStatus;
  String? _selectedChurch;
  XFile? _profileImage;
  Uint8List? _webImageBytes;
  String? _existingPhotoUrl;
  bool _profileVisible = true;
  bool _quietHoursEnabled = false;
  bool _loadingProfile = true;

  // Data Constants
  final List<String> regions = const ['Erongo', 'Khomas', 'Oshana', 'Ohangwena', 'Omusati', 'Oshikoto', 'Kavango East', 'Kavango West', 'Zambezi', 'Kunene', 'Otjozondjupa', 'Omaheke', 'Hardap', '//Karas'];
  final List<String> conferences = const ['Southern Conference', 'Northern Conference'];
  final List<String> languages = const ['English', 'Afrikaans', 'Oshiwambo', 'Damara/Nama', 'Herero', 'Other'];
  final List<String> sexes = const ['Male', 'Female', 'Prefer not to say'];
  final List<String> maritalStatuses = const ['Single', 'Married', 'Divorced', 'Widowed'];

  final Map<String, List<String>> churchesByRegion = const {
    'Erongo': ['Walvis Bay SDA', 'Kuisebmund SDA', 'Swakopmund SDA', 'Vineta SDA', 'Usakos SDA'],
    'Khomas': ['Windhoek Central SDA', 'Katutura SDA', 'Hakahana SDA', 'Eros SDA', 'Bethesda SDA', 'Amazing Grace SDA'],
    'Oshana': ['Oshakati SDA', 'Ondangwa SDA', 'Etunda SDA'],
    'Zambezi': ['Katima Mulilo SDA', 'Choto SDA', 'Bukalo SDA', 'Chinchimane SDA'],
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _churchPositionController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      if (mounted) {
        setState(() {
          _nameController.text = data['name'] ?? user.displayName ?? '';
          _usernameController.text = data['username'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _selectedRegion = data['region'];
          _selectedConference = data['conference'];
          _selectedLanguage = data['language'];
          _selectedSex = data['sex'];
          _selectedMaritalStatus = data['maritalStatus'];
          _selectedChurch = data['church'];
          _churchPositionController.text = data['churchPosition'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _interestsController.text = (data['interests'] as List?)?.join(', ') ?? '';
          _profileVisible = data['profileVisible'] ?? true;
          _quietHoursEnabled = data['quietHoursEnabled'] ?? false;
          _existingPhotoUrl = data['photoURL'] ?? user.photoURL;
          _loadingProfile = false;
        });
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loadingProfile = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? finalPhotoUrl = _existingPhotoUrl;

      // 1. Storage Upload
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
        if (kIsWeb) {
          await ref.putData(_webImageBytes!);
        } else {
          await ref.putFile(File(_profileImage!.path));
        }
        finalPhotoUrl = await ref.getDownloadURL();
      }

      final interestsList = _interestsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final String displayName = _nameController.text.trim();

      // 2. Sync Firebase Auth Profile (Critical for real-time identity)
      await user.updateDisplayName(displayName);
      if (finalPhotoUrl != null) await user.updatePhotoURL(finalPhotoUrl);

      // 3. Sync Firestore Identity Ledger
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': displayName,
        'username': _usernameController.text.trim(),
        'age': int.tryParse(_ageController.text),
        'sex': _selectedSex,
        'maritalStatus': _selectedMaritalStatus,
        'language': _selectedLanguage,
        'region': _selectedRegion,
        'conference': _selectedConference,
        'church': _selectedChurch,
        'churchPosition': _churchPositionController.text.trim(),
        'bio': _bioController.text.trim(),
        'interests': interestsList,
        'photoURL': finalPhotoUrl,
        'profileVisible': _profileVisible,
        'quietHoursEnabled': _quietHoursEnabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Identity Synchronized & Secured", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: Color(0xFF00FFCC),
            behavior: SnackBarBehavior.floating,
          )
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transmission Interrupted: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: _loadingProfile 
        ? const Center(child: CircularProgressIndicator(color: Colors.teal))
        : Stack(
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
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 30),
                              _buildSectionCard("Personal Identity", [
                                _buildField(_nameController, "Full Name", Icons.person, required: true),
                                _buildField(_usernameController, "Unique Username", Icons.alternate_email, required: true),
                                Row(
                                  children: [
                                    Expanded(child: _buildField(_ageController, "Age", Icons.cake, keyboardType: TextInputType.number)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildDropdown("Sex", sexes, _selectedSex, (v) => setState(() => _selectedSex = v))),
                                  ],
                                ),
                                _buildDropdown("Marital Status", maritalStatuses, _selectedMaritalStatus, (v) => setState(() => _selectedMaritalStatus = v)),
                                _buildDropdown("Primary Language", languages, _selectedLanguage, (v) => setState(() => _selectedLanguage = v)),
                                _buildField(_bioController, "Biography / Mission Statement", Icons.edit_note, maxLines: 3),
                                _buildField(_interestsController, "Interests (comma separated)", Icons.auto_awesome),
                              ]),
                              const SizedBox(height: 20),
                              _buildSectionCard("Church & Service", [
                                _buildDropdown("Region", regions, _selectedRegion, (v) => setState(() { _selectedRegion = v; _selectedChurch = null; })),
                                _buildDropdown("Conference", conferences, _selectedConference, (v) => setState(() => _selectedConference = v)),
                                _buildDropdown("Local Church", churchesByRegion[_selectedRegion] ?? [], _selectedChurch, (v) => setState(() => _selectedChurch = v)),
                                _buildField(_churchPositionController, "Service Position", Icons.military_tech),
                              ]),
                              const SizedBox(height: 20),
                              _buildSectionCard("Visibility Settings", [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Public Visibility", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: const Text("Allow community members to find your identity", style: TextStyle(color: Colors.white38, fontSize: 12)),
                                  value: _profileVisible,
                                  activeThumbColor: Colors.teal,
                                  onChanged: (v) => setState(() => _profileVisible = v),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text("Quiet Hours", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: const Text("Pause haptic notifications during rest", style: TextStyle(color: Colors.white38, fontSize: 12)),
                                  value: _quietHoursEnabled,
                                  activeThumbColor: Colors.yellowAccent,
                                  onChanged: (v) => setState(() => _quietHoursEnabled = v),
                                ),
                              ]),
                              const SizedBox(height: 40),
                              _buildSaveButton(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("IDENTITY GOVERNANCE", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildHeader() {
    final avatar = _profileImage != null 
      ? (kIsWeb ? MemoryImage(_webImageBytes!) : FileImage(File(_profileImage!.path)) as ImageProvider)
      : (_existingPhotoUrl != null ? NetworkImage(_existingPhotoUrl!) : null);

    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final file = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (file != null) {
              final bytes = await file.readAsBytes();
              setState(() { _profileImage = file; _webImageBytes = bytes; });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  gradient: LinearGradient(colors: [Colors.teal, const Color(0xFF00FFCC).withValues(alpha: 0.5)])
                ),
              ),
              CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFF1A1A1A),
                backgroundImage: avatar,
                child: avatar == null ? const Icon(Icons.camera_enhance, size: 30, color: Colors.white24) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(FirebaseAuth.instance.currentUser?.email ?? "secure@identity.net", style: const TextStyle(color: Colors.white38, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool required = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        validator: (v) => required && (v == null || v.isEmpty) ? "Field Required" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          floatingLabelStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          filled: true,
          fillColor: Colors.black26,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.teal, width: 2)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    final safeValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue, // Fixed: Using initialValue to satisfy newer Flutter versions
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        items: items.toSet().map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          filled: true,
          fillColor: Colors.black26,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.teal)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 12,
          shadowColor: Colors.teal.withValues(alpha: 0.4),
        ),
        child: const Text("COMMIT CHANGES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }
}
