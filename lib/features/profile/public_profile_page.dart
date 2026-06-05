import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  bool _isFollowing = false;
  bool _loadingFollow = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(widget.userId)
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = doc.exists;
        _loadingFollow = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(widget.userId);

    setState(() => _loadingFollow = true);

    if (_isFollowing) {
      await ref.delete();
    } else {
      await ref.set({'followedAt': FieldValue.serverTimestamp()});
    }

    setState(() {
      _isFollowing = !_isFollowing;
      _loadingFollow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("User not found"));
          }

          final name = data['name'] ?? "User";

          return Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 40,
                child: Text(
                  name.isNotEmpty ? name[0] : "U",
                  style: const TextStyle(fontSize: 24),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _loadingFollow
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _toggleFollow,
                      child: Text(_isFollowing ? "Unfollow" : "Follow"),
                    ),

              const Divider(),

              const SizedBox(height: 10),

              const Text(
                "Posts",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_posts')
                      .where('userId', isEqualTo: widget.userId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, postSnap) {
                    if (!postSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final posts = postSnap.data!.docs;

                    if (posts.isEmpty) {
                      return const Center(child: Text("No posts yet"));
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (_, i) {
                        final p = posts[i];

                        return ListTile(
                          title: Text(p['content'] ?? "No content"),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
