import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String? _photoUrl;
  XFile? _pickedFile;
  Uint8List? _webBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ✅ LOAD PROFILE (CLEAN)
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _photoUrl = data['userPhotoUrl'] ?? user.photoURL;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ PICK IMAGE
  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    setState(() {
      _pickedFile = file;
      _webBytes = bytes;
    });
  }

  // ✅ SAVE PROFILE (CLEAN + SAFE)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? newPhotoUrl = _photoUrl;

      if (_pickedFile != null) {
        final ref = FirebaseStorage.instance.ref(
          'profile_images/${user.uid}.jpg',
        );

        if (kIsWeb) {
          await ref.putData(_webBytes!);
        } else {
          await ref.putFile(File(_pickedFile!.path));
        }

        newPhotoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'userPhotoUrl': newPhotoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(_nameController.text.trim());
      if (newPhotoUrl != null) {
        await user.updatePhotoURL(newPhotoUrl);
      }

      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to save")));
      }
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final previewImage = _pickedFile != null
        ? (kIsWeb
              ? MemoryImage(_webBytes!)
              : FileImage(File(_pickedFile!.path)) as ImageProvider)
        : (_photoUrl != null ? NetworkImage(_photoUrl!) : null);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.black,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// ✅ PROFILE HEADER
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white12,
                          backgroundImage: previewImage,
                          child: previewImage == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ CARD SECTION
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        /// NAME
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "Name"),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                        ),

                        const SizedBox(height: 16),

                        /// BIO
                        TextFormField(
                          controller: _bioController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: "Bio"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ✅ SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
