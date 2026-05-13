// lib/features/resourcehub/resource_hub_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Resource Hub — High-fidelity Opportunity & Asset Sector for SDA Youth.
/// Manages community resources with verified author metadata and cinematic visuals.
class ResourceHubPage extends StatefulWidget {
  const ResourceHubPage({super.key});

  @override
  State<ResourceHubPage> createState() => _ResourceHubPageState();
}

class _ResourceHubPageState extends State<ResourceHubPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  XFile? _pickedImage;
  Uint8List? _webImageBytes;
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAssetImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        if (mounted) setState(() { _pickedImage = file; _webImageBytes = bytes; });
      } else {
        if (mounted) setState(() => _pickedImage = file);
      }
    }
  }

  Future<void> _handlePublish() async {
    final user = FirebaseAuth.instance.currentUser;
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();

    if (user == null || title.isEmpty || desc.isEmpty) {
      _showFeedback("Please fulfill all resource fields", isError: true);
      return;
    }

    setState(() => _isPosting = true);
    try {
      // 1. Fetch Verified Identity Metadata from the Ledger
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String verifiedName = userDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';
      final String? verifiedPhoto = userDoc.data()?['photoURL'] ?? user.photoURL;

      String? imageUrl;

      // 2. Cross-Platform Media Storage
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('resources/${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (kIsWeb) {
          await ref.putData(_webImageBytes!);
        } else {
          await ref.putFile(File(_pickedImage!.path));
        }
        imageUrl = await ref.getDownloadURL();
      }

      // 3. Register Resource with verified identity stamp
      await FirebaseFirestore.instance.collection('resources').add({
        'authorId': user.uid,
        'authorName': verifiedName,
        'authorPhoto': verifiedPhoto,
        'title': title,
        'description': desc,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'resource',
      });

      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        setState(() { _pickedImage = null; _webImageBytes = null; });
        _showFeedback("Mission Asset Successfully Shared");
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) _showFeedback("Transmission Error", isError: true);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handlePurge(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("PURGE RESOURCE?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("This action will permanently remove this opportunity from the community ledger.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('resources').doc(docId).delete();
      _showFeedback("Asset Purged Successfully");
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
          // Cinematic Background
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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    
                    // Asset Composer
                    SliverToBoxAdapter(child: _buildComposer()),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Text(
                          "COMMUNITY LEDGER",
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),

                    _buildResourceStream(),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text("RESOURCE HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildComposer() {
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
          const Text("SHARE A NEW OPPORTUNITY", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          _inputField(_titleController, "Title of Resource", Icons.title),
          _inputField(_descriptionController, "Provide mission context...", Icons.description_outlined, maxLines: 3),
          
          if (_pickedImage != null) _buildImagePreview(),

          Row(
            children: [
              _composerTool(Icons.image_outlined, "ATTACH IMAGE", _pickAssetImage),
              const Spacer(),
              _buildSubmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('resources')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildResourceCard(docs[index]),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildResourceCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ts = data['timestamp'] as Timestamp?;
    final imageUrl = data['imageUrl'];
    final isOwner = data['authorId'] == FirebaseAuth.instance.currentUser?.uid;
    final String authorName = (data['authorName'] ?? 'Mission Member').toString();
    final String? authorPhoto = data['authorPhoto'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null) _buildCardMedia(imageUrl.toString()),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (data['title'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: errorRed, size: 20),
                        onPressed: () => _handlePurge(doc.id),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Verified Identity Sign
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: primaryTeal,
                      backgroundImage: authorPhoto != null ? NetworkImage(authorPhoto) : null,
                      child: authorPhoto == null ? const Icon(Icons.person, size: 8, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      authorName.toUpperCase(),
                      style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const Spacer(),
                    Text(
                      ts != null ? timeago.format(ts.toDate()).toUpperCase() : "SYNCING",
                      style: const TextStyle(color: Colors.white12, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMedia(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Image.network(
        url,
        height: 220, width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(height: 220, color: Colors.white10, child: const Center(child: CircularProgressIndicator(color: electricTeal)));
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: kIsWeb 
          ? Image.memory(_webImageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover)
          : Image.file(File(_pickedImage!.path), height: 180, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }

  Widget _composerTool(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: electricTeal, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
          floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, color: primaryTeal, size: 20),
          filled: true,
          fillColor: Colors.black45,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _isPosting ? null : _handlePublish,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isPosting 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text("TRANSMIT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white12, size: 80),
            SizedBox(height: 20),
            Text("LEDGER EMPTY", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
          ],
        ),
      ),
    );
  }
}
