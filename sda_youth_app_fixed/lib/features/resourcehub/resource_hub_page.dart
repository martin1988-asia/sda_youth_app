import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ResourceHubPage extends StatefulWidget {
  const ResourceHubPage({super.key});

  @override
  State<ResourceHubPage> createState() => _ResourceHubPageState();
}

class _ResourceHubPageState extends State<ResourceHubPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _pickedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _addResource() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    String? imageUrl;
    if (_pickedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('resources')
          .child('${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');
      await ref.putData(await _pickedImage!.readAsBytes());
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('resources').add({
      'authorId': user.uid,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'resource',
    });

    _titleController.clear();
    _descriptionController.clear();
    setState(() => _pickedImage = null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resource shared successfully")),
    );
  }

  Future<void> _deleteResource(DocumentReference ref) async {
    await ref.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resource deleted")),
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
                AppBar(title: const Text("Resource Hub"), backgroundColor: Colors.teal),
                ExpansionTile(
                  title: const Text("Share a Resource / Opportunity"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: "Title",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Description",
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
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("Share"),
                                onPressed: _addResource,
                              ),
                            ],
                          ),
                          if (_pickedImage != null)
                            Image.file(File(_pickedImage!.path), height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('resources')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No resources shared yet."));
                      }

                      final resources = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          final resourceDoc = resources[index];
                          final resource = resourceDoc.data();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    resource['description'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  if (resource['imageUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Image.network(resource['imageUrl']),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    resource['timestamp']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text("Delete"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => _deleteResource(resourceDoc.reference),
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
