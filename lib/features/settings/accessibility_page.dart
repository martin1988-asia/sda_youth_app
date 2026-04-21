import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessibilityPage extends StatefulWidget {
  const AccessibilityPage({super.key});

  @override
  State<AccessibilityPage> createState() => _AccessibilityPageState();
}

class _AccessibilityPageState extends State<AccessibilityPage> {
  bool _darkModeEnabled = false;
  bool _highContrastEnabled = false;
  double _fontSize = 16.0;
  String _selectedLanguage = "English";

  final List<String> languages = [
    "English",
    "Afrikaans",
    "Oshiwambo",
    "Damara/Nama",
    "Herero",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _darkModeEnabled = data['darkModeEnabled'] ?? false;
        _highContrastEnabled = data['highContrastEnabled'] ?? false;
        _fontSize = (data['fontSize'] ?? 16).toDouble();
        _selectedLanguage = data['language'] ?? "English";
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
      'darkModeEnabled': _darkModeEnabled,
      'highContrastEnabled': _highContrastEnabled,
      'fontSize': _fontSize,
      'language': _selectedLanguage,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Accessibility settings saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    AppBar(
                      title: const Text("Accessibility"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Enable Dark Mode"),
                      value: _darkModeEnabled,
                      onChanged: (val) => setState(() => _darkModeEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text("Enable High Contrast Mode"),
                      value: _highContrastEnabled,
                      onChanged: (val) => setState(() => _highContrastEnabled = val),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text("Font Size"),
                      subtitle: Slider(
                        min: 12,
                        max: 24,
                        divisions: 6,
                        value: _fontSize,
                        label: "${_fontSize.toInt()}",
                        onChanged: (val) => setState(() => _fontSize = val),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage, // ✅ fixed
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Language",
                      ),
                      items: languages
                          .map((lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                      validator: (val) =>
                          val == null ? "Please select a language" : null,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Settings"),
                        onPressed: _saveSettings,
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
}
