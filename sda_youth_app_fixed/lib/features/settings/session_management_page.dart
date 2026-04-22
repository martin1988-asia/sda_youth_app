import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionManagementPage extends StatefulWidget {
  const SessionManagementPage({super.key});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  Future<void> _logoutSession(DocumentReference sessionRef) async {
    await sessionRef.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session logged out")),
    );
  }

  Future<void> _logoutAllSessions(User user) async {
    final sessions = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .get();

    for (var doc in sessions.docs) {
      await doc.reference.delete();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All sessions logged out")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

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
                child: Column(
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    AppBar(
                      title: const Text("Session Management"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('sessions')
                            .orderBy('lastActive', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No active sessions found."));
                          }

                          final sessions = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final sessionDoc = sessions[index];
                              final session = sessionDoc.data();
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.devices),
                                  title: Text(session['device'] ?? 'Unknown Device'),
                                  subtitle: Text(
                                    "Last Active: ${session['lastActive'] ?? ''}\n"
                                    "IP: ${session['ipAddress'] ?? ''}",
                                  ),
                                  trailing: ElevatedButton(
                                    child: const Text("Logout"),
                                    onPressed: () => _logoutSession(sessionDoc.reference),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout All Sessions"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _logoutAllSessions(user),
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
