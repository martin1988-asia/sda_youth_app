import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _controller = TextEditingController();

  final List<File> _mediaFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ GET USER NAME
  Future<String> _getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      return (data?['name'] ?? data?['displayName'] ?? 'User').toString();
    } catch (_) {
      return 'User';
    }
  }

  // ✅ PICK IMAGE
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
      setState(() => _mediaFiles.add(File(picked.path)));
    }
  }

  // ✅ UPLOAD FILE
  Future<String?> _uploadFile(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

      final ref = FirebaseStorage.instance.ref('post_media/$fileName');

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'uploadFile failed',
        );
      }
      return null;
    }
  }

  Future<String?> _uploadFirstMedia() async {
    if (_mediaFiles.isEmpty) return null;
    return _uploadFile(_mediaFiles.first);
  }

  // ✅ SAFE POST
  Future<void> _submitPost() async {
    if (_isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = _controller.text.trim();

    if (text.isEmpty && _mediaFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Post cannot be empty")));
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadFirstMedia();
      final name = await _getUserName(user.uid);

      await FirebaseFirestore.instance.collection('community_posts').add({
        'content': text,
        'authorId': user.uid,
        'authorName': name,
        'mediaUrl': imageUrl,
        'mediaType': imageUrl != null ? 'image' : null,
        'likeCount': 0,
        'commentCount': 0,
        'score': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'visibility': 'public',
      });

      await FirebaseAnalytics.instance.logEvent(name: "post_created");

      // ✅ FINAL FIX (NO CRASH)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e, st) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'submitPost failed',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text("Create Post", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Share something inspiring...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (_mediaFiles.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaFiles.length,
                    itemBuilder: (_, i) {
                      final file = _mediaFiles[i];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(file.path, fit: BoxFit.cover)
                              : Image.file(file, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 14),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.tealAccent),
                    onPressed: _pickImage,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("POST"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
