import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageContentPage extends StatelessWidget {
  const ManageContentPage({super.key});

  Future<void> _deleteDoc(BuildContext context, String collection, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this $collection item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
        if (!context.mounted) return; // ✅ safe check before using context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$collection item deleted")),
        );
      } catch (e) {
        if (!context.mounted) return; // ✅ safe check before using context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting $collection: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          Column(
            children: [
              AppBar(
                title: const Text("Manage Content"),
                backgroundColor: Colors.teal,
              ),
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(12),
                      child: ListView(
                        children: [
                          _buildSection(context, "Devotionals", "devotionals"),
                          _buildSection(context, "Events", "events"),
                          _buildSection(context, "Groups", "groups"),
                          _buildSection(context, "Posts", "posts"),
                          _buildSection(context, "Lessons", "lessons"),
                          _buildSection(context, "Announcements", "announcements"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String collection) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection(collection).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No $collection found."));
            }

            final docs = snapshot.data!.docs;
            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final itemTitle = data['title'] ?? data['name'] ?? doc.id;

                String subtitle = '';
                if (collection == 'announcements') {
                  subtitle = data['message'] ?? '';
                } else if (collection == 'devotionals') {
                  subtitle = data['message'] ?? data['verse'] ?? '';
                } else if (collection == 'events') {
                  subtitle = data['description'] ?? data['location'] ?? '';
                } else if (collection == 'groups') {
                  subtitle = data['description'] ?? '';
                } else if (collection == 'lessons') {
                  subtitle = data['summary'] ?? data['memoryVerse'] ?? '';
                } else if (collection == 'posts') {
                  subtitle = data['content'] ?? '';
                }

                final date = data['date'] ?? '';
                final category = data['category'] ?? '';
                final leader = data['leader'] ?? '';
                final weekNumber = data['weekNumber']?.toString() ?? '';
                final membersCount = data['membersCount']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    title: Text(itemTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subtitle.isNotEmpty) Text(subtitle),
                        if (date.isNotEmpty)
                          Text("Date: $date", style: const TextStyle(color: Colors.grey)),
                        if (category.isNotEmpty) Text("Category: $category"),
                        if (leader.isNotEmpty) Text("Leader: $leader"),
                        if (membersCount.isNotEmpty) Text("Members: $membersCount"),
                        if (weekNumber.isNotEmpty) Text("Week: $weekNumber"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteDoc(context, collection, doc.id),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
