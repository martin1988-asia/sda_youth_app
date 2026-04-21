import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchmakingPage extends StatefulWidget {
  const MatchmakingPage({super.key});

  @override
  State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage> {
  Future<void> _likeUser(String targetUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final likesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('likes')
          .doc(targetUserId);

      final existing = await likesRef.get();
      if (existing.exists) {
        await likesRef.delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed like")),
        );
      } else {
        await likesRef.set({'timestamp': FieldValue.serverTimestamp()});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You liked this profile")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _connectWithUser(String targetUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('connections')
          .doc(targetUserId)
          .set({'timestamp': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection request sent")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to use matchmaking")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Matchmaking"), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('uid', isNotEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No profiles available"));
          }

          final profiles = snapshot.data!.docs;
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index].data();
              final targetUserId = profiles[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.teal),
                  title: Text(profile['displayName'] ?? 'Anonymous'),
                  subtitle: Text(profile['bio'] ?? 'No bio available'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.red),
                        onPressed: () => _likeUser(targetUserId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.handshake, color: Colors.blue),
                        onPressed: () => _connectWithUser(targetUserId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
