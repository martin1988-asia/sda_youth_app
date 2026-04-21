import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestimoniesPage extends StatefulWidget {
  const TestimoniesPage({super.key});

  @override
  State<TestimoniesPage> createState() => _TestimoniesPageState();
}

class _TestimoniesPageState extends State<TestimoniesPage> {
  final _testimonyController = TextEditingController();

  @override
  void dispose() {
    _testimonyController.dispose();
    super.dispose();
  }

  Future<void> _submitTestimony() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _testimonyController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your testimony before submitting")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('testimonies').add({
      'userId': user.uid,
      'userEmail': user.email,
      'content': _testimonyController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    });

    _testimonyController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Testimony shared successfully")),
    );
  }

  Future<void> _likeTestimony(DocumentReference ref, int currentLikes) async {
    await ref.update({'likes': currentLikes + 1});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You liked this testimony")),
    );
  }

  Future<void> _deleteTestimony(DocumentReference ref) async {
    await ref.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Testimony deleted")),
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
                AppBar(title: const Text("Testimonies"), backgroundColor: Colors.teal),
                ExpansionTile(
                  title: const Text("Share Your Testimony"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _testimonyController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: "Write your testimony",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text("Submit"),
                            onPressed: _submitTestimony,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('testimonies')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No testimonies shared yet."));
                      }

                      final testimonies = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: testimonies.length,
                        itemBuilder: (context, index) {
                          final testimonyDoc = testimonies[index];
                          final testimony = testimonyDoc.data();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testimony['content'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Shared by: ${testimony['userEmail'] ?? ''}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.thumb_up, color: Colors.blue),
                                            onPressed: () => _likeTestimony(
                                              testimonyDoc.reference,
                                              testimony['likes'] ?? 0,
                                            ),
                                          ),
                                          Text("${testimony['likes'] ?? 0} likes"),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteTestimony(testimonyDoc.reference),
                                      ),
                                    ],
                                  ),
                                ],
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
}
