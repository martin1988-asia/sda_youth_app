import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedRegion;
  String? _selectedConference;
  String? _selectedLanguage;
  String? _customLanguage;
  bool _showCustomLanguageField = false;
  String? _selectedSex;
  String? _selectedMaritalStatus;
  String? _selectedChurch;

  XFile? _profileImage;
  Uint8List? _webImageBytes;

  final List<String> regions = [
    'Erongo','Khomas','Oshana','Ohangwena','Omusati','Oshikoto',
    'Kavango East','Kavango West','Zambezi','Kunene',
    'Otjozondjupa','Omaheke','Hardap','//Karas',
  ];

  final List<String> conferences = ['Southern Conference','Northern Conference'];
  final List<String> languages = ['English','Afrikaans','Oshiwambo','Damara/Nama','Herero','Other'];
  final List<String> sexes = ['Male','Female','Prefer not to say'];
  final List<String> maritalStatuses = ['Single','Married','Divorced','Widowed'];

  // Example list of churches (replace with full SDA Namibia list or fetch from Firestore)
  final List<String> churches = [
    'Windhoek Central SDA',
    'Walvis Bay SDA',
    'Swakopmund SDA',
    'Oshakati SDA',
    'Katutura SDA',
    'Rundu SDA',
    'Keetmanshoop SDA',
    'Gobabis SDA',
    'Ondangwa SDA',
    'Eenhana SDA',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImage = pickedFile;
          _webImageBytes = bytes;
        });
      } else {
        setState(() => _profileImage = pickedFile);
      }
    }
  }

  Future<String?> _uploadImage(User user) async {
    if (_profileImage == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
      final bytes = await _profileImage!.readAsBytes();
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final imageUrl = await _uploadImage(user);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'church': _selectedChurch,
            'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
            'region': _selectedRegion,
            'conference': _selectedConference,
            'language': _selectedLanguage == 'Other' ? _customLanguage : _selectedLanguage,
            'sex': _selectedSex,
            'maritalStatus': _selectedMaritalStatus,
            'photoUrl': imageUrl,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          Navigator.pop(context); // close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );

          // ✅ Redirect to HomePage after successful save
          Navigator.pushReplacementNamed(context, '/home');
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Image.asset('assets/sda_logo.png', height: 70),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: _profileImage != null
                                ? (kIsWeb
                                    ? (_webImageBytes != null ? MemoryImage(_webImageBytes!) : null)
                                    : FileImage(File(_profileImage!.path)))
                                : null,
                            child: _profileImage == null
                                ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_nameController, 'Full Name', true),
                        const SizedBox(height: 12),
                        _buildTextField(_ageController, 'Age (optional)', false,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),

                        // Marital Status
                        _buildDropdown('Marital Status', maritalStatuses, _selectedMaritalStatus,
                            (val) => setState(() => _selectedMaritalStatus = val)),
                        const SizedBox(height: 12),

                        // Church Autocomplete
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return churches.where((c) =>
                              c.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (selection) => setState(() => _selectedChurch = selection),
                          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Church',
                                labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Please select a church' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Language with "Other"
                        _buildDropdown('Language', languages, _selectedLanguage, (val) {
                          setState(() {
                            _selectedLanguage = val;
                            _showCustomLanguageField = val == 'Other';
                          });
                        }),
                        if (_showCustomLanguageField)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Enter your language'),
                              onChanged: (val) => _customLanguage = val,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        const SizedBox(height: 12),

                        _buildDropdown('Sex', sexes, _selectedSex,
                            (val) => setState(() => _selectedSex = val)),
                        const SizedBox(height: 12),
                        _buildDropdown('Region', regions, _selectedRegion,
                            (val) => setState(() => _selectedRegion = val)),
                        const SizedBox(height: 12),
                        _buildDropdown('Conference', conferences, _selectedConference,
                            (val) => setState(() => _selectedConference = val)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Profile'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              backgroundColor: Colors.blueAccent.withOpacity(0.9),
                              foregroundColor: Colors.white,
                              elevation: 6,
                            ),
                            onPressed: _saveProfile,
                          ),
                        ),
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

  Widget _buildTextField(TextEditingController controller, String label, bool required,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: required
          ? (val) => val == null || val.isEmpty ? 'Please enter $label' : null
          : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.black87,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Please select $label' : null,
    );
  }
}

