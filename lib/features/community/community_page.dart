import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _postController = TextEditingController();
  XFile? _pickedImage;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _postController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter text before posting")),
      );
      return;
    }

    String? imageUrl;
    if (_pickedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('community_posts')
          .child('${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');
      await ref.putData(await _pickedImage!.readAsBytes());
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'authorId': user.uid,
      'content': _postController.text.trim(),
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': [],
    });

    _postController.clear();
    setState(() => _pickedImage = null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post created successfully')),
    );
  }

  Future<void> _addComment(DocumentReference postRef, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || comment.trim().isEmpty) return;

    await postRef.update({
      'comments': FieldValue.arrayUnion([
        {
          'userId': user.uid,
          'comment': comment.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        }
      ])
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Comment added")),
    );
  }

  Future<void> _deletePost(DocumentReference postRef) async {
    await postRef.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Post deleted")),
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
                AppBar(title: const Text("Community Feed"), backgroundColor: Colors.teal),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _postController,
                        decoration: const InputDecoration(
                          hintText: "Share something with the community...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: _pickImage,
                          ),
                          ElevatedButton(
                            onPressed: _createPost,
                            child: const Text("Post"),
                          ),
                        ],
                      ),
                      if (_pickedImage != null)
                        Image.file(File(_pickedImage!.path), height: 120),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No posts yet."));
                      }

                      final posts = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postDoc = posts[index];
                          final post = postDoc.data();
                          final comments = List<Map<String, dynamic>>.from(
                              post['comments'] ?? []);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post['content'] ?? '',
                                      style: const TextStyle(fontSize: 16)),
                                  if (post['imageUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Image.network(post['imageUrl']),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.thumb_up),
                                            onPressed: () async {
                                              await postDoc.reference.update({
                                                'likes': (post['likes'] ?? 0) + 1,
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("You liked this post")),
                                              );
                                            },
                                          ),
                                          Text("${post['likes'] ?? 0} likes"),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deletePost(postDoc.reference),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const Text("Comments:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                  for (var c in comments)
                                    ListTile(
                                      leading: const Icon(Icons.comment),
                                      title: Text(c['comment'] ?? ''),
                                      subtitle: Text(c['timestamp']?.toString() ?? ''),
                                    ),
                                  TextField(
                                    decoration: const InputDecoration(
                                      hintText: "Add a comment...",
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (val) =>
                                        _addComment(postDoc.reference, val),
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
