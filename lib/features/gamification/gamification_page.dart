import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  int _points = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      setState(() => _points = doc.data()?['points'] ?? 0);
    }
  }

  Future<void> _addPoints(int amount) async {
    if (_user == null) return;
    _points += amount;
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
      'points': _points,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You earned $amount points!")),
    );
    setState(() {});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _leaderboard() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .limit(10)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _badges() {
    if (_user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('badges')
        .snapshots();
  }

  Future<void> _awardBadge(String badgeName) async {
    if (_user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('badges')
        .add({
      'name': badgeName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Badge earned: $badgeName")),
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
          Column(
            children: [
              AppBar(title: const Text("Gamification"), backgroundColor: Colors.teal),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const Text(
                      "Your Progress",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: Text("Points: $_points"),
                      trailing: ElevatedButton(
                        child: const Text("Earn 10 Points"),
                        onPressed: () => _addPoints(10),
                      ),
                    ),
                    const Divider(),
                    const Text(
                      "Your Badges",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _badges(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text("No badges yet.");
                        }
                        final badges = snapshot.data!.docs;
                        return Wrap(
                          spacing: 8,
                          children: badges.map((doc) {
                            final badge = doc.data();
                            return Chip(
                              label: Text(badge['name'] ?? 'Badge'),
                              avatar: const Icon(Icons.emoji_events, color: Colors.orange),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.emoji_events),
                      label: const Text("Award Test Badge"),
                      onPressed: () => _awardBadge("Test Badge"),
                    ),
                    const Divider(),
                    const Text(
                      "Leaderboard",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _leaderboard(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text("No leaderboard data yet.");
                        }
                        final users = snapshot.data!.docs;
                        return Column(
                          children: users.map((doc) {
                            final data = doc.data();
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(data['displayName'] ?? 'Unknown'),
                              subtitle: Text("${data['points'] ?? 0} points"),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
