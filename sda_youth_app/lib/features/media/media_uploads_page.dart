import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MediaUploadsPage extends StatefulWidget {
  const MediaUploadsPage({super.key});

  @override
  State<MediaUploadsPage> createState() => _MediaUploadsPageState();
}

class _MediaUploadsPageState extends State<MediaUploadsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _mediaType; // "image" or "video"
  bool _isLoading = false;

  Future<void> _pickFile({required bool isVideo}) async {
    final pickedFile = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _mediaType = isVideo ? "video" : "image";
      });
    }
  }

  Future<void> _uploadFile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file before uploading")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileName =
          "${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${_mediaType == 'video' ? 'mp4' : 'jpg'}";
      final storageRef =
          FirebaseStorage.instance.ref().child("uploads/$fileName");

      await storageRef.putFile(_selectedFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('media').add({
        'userId': user.uid,
        'url': downloadUrl,
        'mediaType': _mediaType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _selectedFile = null;
        _mediaType = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Media uploaded successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading file: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Media Uploads"), backgroundColor: Colors.teal),
      body: Column(
        children: [
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _mediaType == "image"
                  ? Image.file(_selectedFile!, height: 200, fit: BoxFit.cover)
                  : const Icon(Icons.videocam, size: 100, color: Colors.teal),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text("Pick Image"),
                onPressed: () => _pickFile(isVideo: false),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.videocam),
                label: const Text("Pick Video"),
                onPressed: () => _pickFile(isVideo: true),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: _isLoading ? const Text("Uploading...") : const Text("Upload"),
                onPressed: _isLoading ? null : _uploadFile,
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('media')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No media uploaded yet."));
                }
                final mediaItems = snapshot.data!.docs;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: mediaItems.length,
                  itemBuilder: (context, index) {
                    final media = mediaItems[index].data();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: media['mediaType'] == 'image'
                          ? Image.network(media['url'], fit: BoxFit.cover)
                          : Container(
                              color: Colors.black12,
                              child: const Center(
                                child: Icon(Icons.videocam, color: Colors.teal),
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
    );
  }
}
