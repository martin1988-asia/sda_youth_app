import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchmakingPage extends StatefulWidget {
  const MatchmakingPage({super.key});

  @override
  State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage> {
  bool _mentorshipOptIn = false;
  bool _friendshipOptIn = false;
  String _interest = '';
  String _region = '';
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('matchmaking')
        .doc('preferences')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _mentorshipOptIn = data['mentorshipOptIn'] ?? false;
        _friendshipOptIn = data['friendshipOptIn'] ?? false;
        _interest = data['interest'] ?? '';
        _region = data['region'] ?? '';
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('matchmaking')
        .doc('preferences')
        .set({
      'mentorshipOptIn': _mentorshipOptIn,
      'friendshipOptIn': _friendshipOptIn,
      'interest': _interest,
      'region': _region,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preferences saved")),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _suggestedMatches() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('users');
    if (_mentorshipOptIn) {
      query = query.where('role', isEqualTo: 'mentor');
    } else if (_friendshipOptIn) {
      query = query.where('role', isEqualTo: 'youth');
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Matchmaking"), backgroundColor: Colors.teal),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)), // ✅ fixed
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                "Opt-in Preferences",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text("Mentorship Matching"),
                subtitle: const Text("Find or become a mentor"),
                value: _mentorshipOptIn,
                onChanged: (val) => setState(() => _mentorshipOptIn = val),
              ),
              SwitchListTile(
                title: const Text("Friendship Matching"),
                subtitle: const Text("Connect with SDA youth peers"),
                value: _friendshipOptIn,
                onChanged: (val) => setState(() => _friendshipOptIn = val),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Interest (e.g. Bible study, music)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _interest = val,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Region (e.g. Namibia, Southern Africa)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _region = val,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Preferences"),
                onPressed: _savePreferences,
              ),
              const Divider(),
              const Text(
                "Suggested Matches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _suggestedMatches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No matches found.");
                  }
                  final matches = snapshot.data!.docs;
                  return Column(
                    children: matches.map((doc) {
                      final user = doc.data();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(user['name'] ?? 'Unknown'),
                          subtitle: Text(
                            "${user['interest'] ?? ''} • ${user['region'] ?? ''}",
                          ),
                          trailing: ElevatedButton(
                            child: const Text("Connect"),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Connection request sent to ${user['name'] ?? 'user'}",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
