import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  Future<void> _handleAction(BuildContext context, String action, String reportId, String userId) async {
    try {
      if (action == "dismiss") {
        await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report dismissed")),
        );
      } else if (action == "ban") {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({"status": "banned"});
        await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User banned")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
                title: const Text("Moderation Queue"),
                backgroundColor: Colors.teal,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('reports').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No reports found."));
                    }

                    final reports = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index].data();
                        final id = reports[index].id;
                        final userId = report['userId'] ?? 'Unknown';

                        return Card(
                          margin: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text("Reported User: $userId"),
                            subtitle: Text("Reason: ${report['reason'] ?? 'No reason provided'}"),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _handleAction(context, value, id, userId),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: "dismiss",
                                  child: Text("Dismiss Report"),
                                ),
                                const PopupMenuItem(
                                  value: "ban",
                                  child: Text("Ban User"),
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
        ],
      ),
    );
  }
}
