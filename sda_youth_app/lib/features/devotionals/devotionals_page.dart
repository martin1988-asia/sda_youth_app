import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DevotionalsPage extends StatefulWidget {
  const DevotionalsPage({super.key});

  @override
  State<DevotionalsPage> createState() => _DevotionalsPageState();
}

class _DevotionalsPageState extends State<DevotionalsPage> {
  final _titleController = TextEditingController();
  final _verseController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _verseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _addDevotional() async {
    if (_titleController.text.trim().isEmpty ||
        _verseController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('devotionals').add({
      'title': _titleController.text.trim(),
      'verse': _verseController.text.trim(),
      'message': _messageController.text.trim(),
      'date': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _verseController.clear();
    _messageController.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Devotional added successfully")),
    );
  }

  Future<void> _saveReflection(String devotionalId, String reflection) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || reflection.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reflection before saving")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('devotionals')
        .doc(devotionalId)
        .collection('reflections')
        .add({
      'userId': user.uid,
      'userEmail': user.email,
      'reflection': reflection.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reflection saved")),
    );
  }

  Future<void> _toggleFavorite(String devotionalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(devotionalId);

    final favDoc = await favRef.get();

    if (favDoc.exists) {
      await favRef.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from favorites")),
      );
    } else {
      await favRef.set({'timestamp': FieldValue.serverTimestamp()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to favorites")),
      );
    }
  }

  Future<bool> _isFavorite(String devotionalId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final favDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(devotionalId)
        .get();

    return favDoc.exists;
  }

  Widget _reflectionInput(String devotionalId) {
    final controller = TextEditingController();
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Write your reflection",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Save Reflection"),
          onPressed: () {
            _saveReflection(devotionalId, controller.text);
            controller.clear();
          },
        ),
      ],
    );
  }

  Widget _reflectionList(String devotionalId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('devotionals')
          .doc(devotionalId)
          .collection('reflections')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No reflections yet.");
        }
        final reflections = snapshot.data!.docs;
        return Column(
          children: reflections.map((doc) {
            final ref = doc.data();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.comment),
                title: Text(ref['reflection'] ?? ''),
                subtitle: Text("${ref['userEmail'] ?? ''}"),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)), // ✅ fixed
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        children: [
                          ExpansionTile(
                            title: const Text("Add New Devotional (Admin)"),
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
                                      controller: _verseController,
                                      decoration: const InputDecoration(
                                        labelText: "Bible Verse",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _messageController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: "Message",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text("Add Devotional"),
                                      onPressed: _addDevotional,
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
                                  .collection('devotionals')
                                  .orderBy('date', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text("No devotionals yet."));
                                }

                                final devotionals = snapshot.data!.docs;
                                return ListView.builder(
                                  itemCount: devotionals.length,
                                  itemBuilder: (context, index) {
                                    final devoDoc = devotionals[index];
                                    final devo = devoDoc.data();

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  devo['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                FutureBuilder<bool>(
                                                  future: _isFavorite(devoDoc.id),
                                                  builder: (context, favSnapshot) {
                                                    final isFav = favSnapshot.data ?? false;
                                                    return IconButton(
                                                      icon: Icon(
                                                        isFav ? Icons.favorite : Icons.favorite_border,
                                                        color: isFav ? Colors.red : Colors.grey,
                                                      ),
                                                      onPressed: () => _toggleFavorite(devoDoc.id),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              devo['verse'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              devo['message'] ?? '',
                                              style: const TextStyle(fontSize: 15),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              devo['date']?.toString() ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const Divider(),
                                            _reflectionInput(devoDoc.id),
                                            const SizedBox(height: 8),
                                            _reflectionList(devoDoc.id),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

