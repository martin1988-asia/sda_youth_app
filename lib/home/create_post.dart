// lib/home/create_post.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';

import '../services/post_service.dart';

/// Create Post Sector — World-Class Content Studio for SDA Youth.
/// Ensures every post is stamped with a verified, real-time identity.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedMedia;
  bool _isLoading = false;
  String? _mediaType; // "image" | "video"

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
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
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = FirebaseStorage.instance.ref().child(path).child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      return null;
    }
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final body = _textController.text.trim();
    if (body.isEmpty && _selectedMedia == null) return;

    setState(() => _isLoading = true);

    try {
      String? mediaUrl;
      if (_selectedMedia != null && _mediaType != null) {
        mediaUrl = await _uploadFile(_selectedMedia!, 'post_media');
        if (_mediaType == "video") {
          final thumbPath = await VideoThumbnail.thumbnailFile(
            video: _selectedMedia!.path,
            imageFormat: ImageFormat.JPEG,
            maxHeight: 200,
            quality: 75,
          );
          if (thumbPath != null) await _uploadFile(File(thumbPath), 'post_thumbnails');
        }
      }

      final ref = await PostService.createCommunityPost(content: body, imageUrl: mediaUrl);
      await FirebaseAnalytics.instance.logEvent(name: "post_created");

      if (mounted) {
        if (ref != null) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blessed! Your post is live."), backgroundColor: Color(0xFF00FFCC)));
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transmission Interrupted: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
        title: const Text("NEW POST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("POST", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xff0e1a2b), Color(0xFF050505)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Real-time Identity Header 
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data() ?? {};
                          final String name = data['name'] ?? 'Mission Member';
                          final String? photo = data['photoURL'];

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF008080),
                                backgroundImage: photo != null ? NetworkImage(photo) : null,
                                child: photo == null ? const Icon(Icons.person, color: Colors.white24) : null,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  const Text("PUBLIC FEED", style: TextStyle(color: Color(0xFF00FFCC), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(hintText: "What's on your heart?", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
                      ),
                      if (_selectedMedia != null) _buildMediaPreview(),
                    ],
                  ),
                ),
              ),
              _buildBottomTools(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _mediaType == "image"
                ? Image.file(_selectedMedia!, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 250, width: double.infinity, color: Colors.black54, child: const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Color(0xFF008080)))),
          ),
          Positioned(top: 12, right: 12, child: GestureDetector(onTap: () => setState(() { _selectedMedia = null; _mediaType = null; }), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)))),
        ],
      ),
    );
  }

  Widget _buildBottomTools() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12, left: 24, right: 24, top: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), border: const Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          const Text("Add to post", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.image_outlined, color: Color(0xFF00FFCC)), onPressed: () => _pickMedia(isVideo: false)),
          IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.orangeAccent), onPressed: () => _pickMedia(isVideo: true)),
          IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.yellowAccent), onPressed: () {}),
        ],
      ),
    );
  }
}
