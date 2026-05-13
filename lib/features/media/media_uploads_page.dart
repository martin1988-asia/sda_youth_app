// lib/features/media/media_uploads_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/titan_shimmer.dart';

/// Media Vault — High-fidelity Visual Sector for SDA Youth.
/// Manages community galleries with byte-optimized uploads and progress tracking.
class MediaUploadsPage extends StatefulWidget {
  const MediaUploadsPage({super.key});

  @override
  State<MediaUploadsPage> createState() => _MediaUploadsPageState();
}

class _MediaUploadsPageState extends State<MediaUploadsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedXFile;
  Uint8List? _webImageBytes;
  String? _mediaType; 
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickAsset({required bool isVideo}) async {
    try {
      final pickedFile = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedXFile = pickedFile;
            _webImageBytes = bytes;
            _mediaType = isVideo ? "video" : "image";
          });
        }
      }
    } catch (e) {
      _showFeedback("Gallery access denied", isError: true);
    }
  }

  Future<void> _handleTransmission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _webImageBytes == null) {
      _showFeedback("No valid asset detected", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Resolve Verified Identity from the Ledger
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String verifiedName = userDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';
      final String? verifiedPhoto = userDoc.data()?['photoURL'] ?? user.photoURL;

      // 2. Prepare Storage Reference
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String ext = _mediaType == 'video' ? 'mp4' : 'jpg';
      final String mime = _mediaType == 'video' ? 'video/mp4' : 'image/jpeg';
      final storageRef = FirebaseStorage.instance.ref().child("community_vault/${user.uid}_$timestamp.$ext");

      // 3. Byte-Stream Upload with Progress Listener
      final uploadTask = storageRef.putData(
        _webImageBytes!,
        SettableMetadata(contentType: mime),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final TaskSnapshot finishedSnapshot = await uploadTask;
      final String downloadUrl = await finishedSnapshot.ref.getDownloadURL();

      // 4. Finalize Ledger Entry
      await FirebaseFirestore.instance.collection('media').add({
        'userId': user.uid,
        'authorName': verifiedName,
        'authorPhoto': verifiedPhoto,
        'url': downloadUrl,
        'mediaType': _mediaType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseAnalytics.instance.logEvent(name: "media_transmission_complete");

      if (mounted) {
        setState(() { _selectedXFile = null; _webImageBytes = null; _mediaType = null; });
        _showFeedback("Transmission Successful");
      }
    } catch (e) {
      _showFeedback("Upload Failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? errorRed : electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildUploadDock(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 10, 24, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "COMMUNITY VAULT", 
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)
                        ),
                      ),
                    ),
                    Expanded(child: _buildMediaGrid()),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.go('/home'),
          ),
          const Text("MEDIA HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildUploadDock() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          if (_selectedXFile != null) _buildSelectedPreview(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _studioTool(Icons.add_photo_alternate_outlined, "PHOTO", () => _pickAsset(isVideo: false)),
              _studioTool(Icons.video_call_outlined, "VIDEO", () => _pickAsset(isVideo: true)),
              _buildTransmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _mediaType == "image"
                ? Image.memory(_webImageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 180, width: double.infinity, color: Colors.black54, child: const Center(child: Icon(Icons.play_circle_outline, color: electricTeal, size: 48))),
          ),
          Positioned(
            top: 10, right: 10,
            child: GestureDetector(
              onTap: () => setState(() { _selectedXFile = null; _webImageBytes = null; _mediaType = null; }),
              child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _studioTool(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: electricTeal, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildTransmitButton() {
    return InkWell(
      onTap: _isUploading ? null : _handleTransmission,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedXFile == null ? Colors.white.withValues(alpha: 0.1) : primaryTeal,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("TRANSMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('media').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const TitanShimmer.rectangular(height: 100),
           );
        }
        
        final items = snapshot.data?.docs ?? [];
        if (items.isEmpty) return _buildEmptyState();

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data();
            final isVideo = data['mediaType'] == 'video';
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      data['url'], 
                      fit: BoxFit.cover, 
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white10),
                    ),
                    if (isVideo) Container(
                      color: Colors.black26,
                      child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _uploadProgress, color: electricTeal, strokeWidth: 6),
            const SizedBox(height: 24),
            Text(
              "${(_uploadProgress * 100).toInt()}% TRANSMITTED",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_mosaic_outlined, color: Colors.white.withValues(alpha: 0.05), size: 80),
          const SizedBox(height: 16),
          const Text("VAULT EMPTY", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
