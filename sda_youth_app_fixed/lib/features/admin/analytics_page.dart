import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  Future<int> _getCount(String collection) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(collection).get();
      return snapshot.docs.length;
    } catch (_) {
      return 0; // fallback if query fails
    }
  }

  Future<Map<String, int>> _loadStats() async {
    final users = await _getCount('users');
    final posts = await _getCount('posts');
    final events = await _getCount('events');
    final announcements = await _getCount('announcements');
    final groups = await _getCount('groups');
    final lessons = await _getCount('lessons');
    final devotionals = await _getCount('devotionals');
    return {
      'users': users,
      'posts': posts,
      'events': events,
      'announcements': announcements,
      'groups': groups,
      'lessons': lessons,
      'devotionals': devotionals,
    };
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
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
          Column(
            children: [
              AppBar(
                title: const Text("Analytics"),
                backgroundColor: Colors.teal,
              ),
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder<Map<String, int>>(
                        future: _loadStats(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Error loading analytics: ${snapshot.error}"),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Text("No analytics data available."),
                            );
                          }

                          final stats = snapshot.data!;
                          return ListView(
                            children: [
                              _buildStatCard("Total Users", stats['users'] ?? 0, Colors.blue),
                              _buildStatCard("Total Posts", stats['posts'] ?? 0, Colors.green),
                              _buildStatCard("Total Events", stats['events'] ?? 0, Colors.orange),
                              _buildStatCard("Total Announcements", stats['announcements'] ?? 0, Colors.purple),
                              _buildStatCard("Total Groups", stats['groups'] ?? 0, Colors.teal),
                              _buildStatCard("Total Lessons", stats['lessons'] ?? 0, Colors.red),
                              _buildStatCard("Total Devotionals", stats['devotionals'] ?? 0, Colors.indigo),
                            ],
                          );
                        },
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
}
