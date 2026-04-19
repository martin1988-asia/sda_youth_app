import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  String? _selectedRegion;
  String? _selectedLanguage;
  String? _selectedSex;

  final List<String> regions = [
    'Erongo','Khomas','Oshana','Ohangwena','Omusati','Oshikoto',
    'Kavango East','Kavango West','Zambezi','Kunene',
    'Otjozondjupa','Omaheke','Hardap','//Karas',
  ];

  final List<String> languages = [
    'English','Afrikaans','Oshiwambo','Damara/Nama','Herero','Other',
  ];

  final List<String> sexes = [
    'Male','Female','Prefer not to say',
  ];

  Future<void> _sendConnectionRequest(String targetUserId, String targetName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('connections').add({
      'fromUserId': currentUser.uid,
      'toUserId': targetUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connection request sent to $targetName")),
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
            child: Column(
              children: [
                AppBar(title: const Text("Connections & Matchmaking"), backgroundColor: Colors.teal),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildDropdown("Region", regions, _selectedRegion,
                          (val) => setState(() => _selectedRegion = val)),
                      const SizedBox(height: 8),
                      _buildDropdown("Language", languages, _selectedLanguage,
                          (val) => setState(() => _selectedLanguage = val)),
                      const SizedBox(height: 8),
                      _buildDropdown("Sex", sexes, _selectedSex,
                          (val) => setState(() => _selectedSex = val)),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No users found."));
                      }

                      final currentUser = FirebaseAuth.instance.currentUser;
                      final users = snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        if (doc.id == currentUser?.uid) return false;
                        if (_selectedRegion != null && data['region'] != _selectedRegion) return false;
                        if (_selectedLanguage != null && data['language'] != _selectedLanguage) return false;
                        if (_selectedSex != null && data['sex'] != _selectedSex) return false;
                        return true;
                      }).toList();

                      if (users.isEmpty) {
                        return const Center(child: Text("No matches found."));
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userDoc = users[index];
                          final userData = userDoc.data();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: ListTile(
                              leading: userData['photoUrl'] != null
                                  ? CircleAvatar(backgroundImage: NetworkImage(userData['photoUrl']))
                                  : const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(userData['name'] ?? 'Unknown'),
                              subtitle: Text(
                                "${userData['church'] ?? ''} • ${userData['region'] ?? ''} • ${userData['language'] ?? ''}",
                              ),
                              trailing: ElevatedButton(
                                child: const Text("Connect"),
                                onPressed: () => _sendConnectionRequest(userDoc.id, userData['name'] ?? 'Unknown'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
