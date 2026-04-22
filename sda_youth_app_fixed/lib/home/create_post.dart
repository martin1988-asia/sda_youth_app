import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../notifications_helper.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  File? _selectedMedia;
  bool _isLoading = false;
  String? _mediaType; // "image" or "video"

  Future<void> _pickMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
        _mediaType = isVideo ? "video" : "image";
      });
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(path).child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Upload failed: $e");
      return null;
    }
  }

  Future<Map<String, String?>> _uploadMedia(File file, String type) async {
    String? mediaUrl = await _uploadFile(file, 'post_media');
    String? thumbnailUrl;
    if (type == "video") {
      try {
        final thumbPath = await VideoThumbnail.thumbnailFile(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 200,
          quality: 75,
        );
        if (thumbPath != null) {
          final thumbFile = File(thumbPath);
          thumbnailUrl = await _uploadFile(thumbFile, 'post_thumbnails');
        }
      } catch (e) {
        debugPrint("Thumbnail generation failed: $e");
      }
    }
    return {"mediaUrl": mediaUrl, "thumbnailUrl": thumbnailUrl};
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final body = _textController.text.trim();
    final title = _titleController.text.trim();

    if (body.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something or select media.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? mediaUrl;
      String? thumbnailUrl;
      if (_selectedMedia != null && _mediaType != null) {
        final result = await _uploadMedia(_selectedMedia!, _mediaType!);
        mediaUrl = result["mediaUrl"];
        thumbnailUrl = result["thumbnailUrl"];
      }

      final postRef = await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'title': title.isNotEmpty ? title : 'Post',
        'body': body,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'mediaType': _mediaType,
        'timestamp': FieldValue.serverTimestamp(),
        'reactions': {},
        'shares': 0,
      });

      // 🔔 Notify friends
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .get();
      for (var doc in friendsSnapshot.docs) {
        final friendId = doc.id;
        await NotificationsHelper.sendPostNotification(
          toUserId: friendId,
          fromUserId: user.uid,
          postId: postRef.id,
        );
      }

      // 🔔 Notify admins
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      for (var adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;
        await NotificationsHelper.sendModerationNotification(
          toAdminId: adminId, // ✅ fixed
          fromUserId: user.uid,
          postId: postRef.id,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post created successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error creating post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create post: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _submitPost,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)), // ✅ fixed
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Image.asset('assets/sda_logo.png', height: 70),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedMedia != null)
                    Stack(
                      children: [
                        _mediaType == "image"
                            ? Image.file(_selectedMedia!, height: 200, fit: BoxFit.cover)
                            : const Icon(Icons.videocam, size: 100, color: Colors.teal),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _selectedMedia = null),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickMedia(isVideo: false),
                        icon: const Icon(Icons.photo),
                        label: const Text("Add Image"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickMedia(isVideo: true),
                        icon: const Icon(Icons.videocam),
                        label: const Text("Add Video"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitPost,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          child: const Text("Post"),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
