import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  Future<void> _removeFavorite(String devotionalId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(devotionalId)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from favorites")),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to remove favorite")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view favorites")),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
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
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('favorites')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, favSnapshot) {
                          if (favSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No favorites yet."));
                          }

                          final favorites = favSnapshot.data!.docs;

                          return ListView.builder(
                            itemCount: favorites.length,
                            itemBuilder: (context, index) {
                              final favDoc = favorites[index];
                              final devotionalId = favDoc.id;

                              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('devotionals')
                                    .doc(devotionalId)
                                    .get(),
                                builder: (context, devoSnapshot) {
                                  if (!devoSnapshot.hasData || !devoSnapshot.data!.exists) {
                                    return const ListTile(
                                      title: Text("Devotional not found"),
                                    );
                                  }

                                  final devo = devoSnapshot.data!.data()!;
                                  final date = devo['date'];
                                  String dateText = '';
                                  if (date is Timestamp) {
                                    dateText = DateFormat('yyyy-MM-dd').format(date.toDate());
                                  } else if (date is String) {
                                    dateText = date;
                                  }

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      leading: const Icon(Icons.bookmark, color: Colors.blueAccent),
                                      title: Text(
                                        devo['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        devo['verse'] ?? '',
                                        style: const TextStyle(color: Colors.blueGrey),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            dateText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              await _removeFavorite(devotionalId, context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
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
