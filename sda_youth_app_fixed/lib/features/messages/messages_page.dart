import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'compose_message_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMessageList(Query query, String emptyLabel) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(emptyLabel, style: const TextStyle(color: Colors.white70)),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            final msg = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6), // ✅ fixed
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['text'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "From: ${msg['senderEmail'] ?? ''}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (msg['timestamp'] != null)
                    Text(
                      "At: ${(msg['timestamp'] as Timestamp).toDate().toLocal()}",
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)), // ✅ fixed
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset('assets/sda_logo.png', height: 70),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blueAccent,
                  tabs: const [
                    Tab(icon: Icon(Icons.inbox)),
                    Tab(icon: Icon(Icons.send)),
                    Tab(icon: Icon(Icons.drafts)),
                  ],
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4), // ✅ polished
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMessageList(
                          FirebaseFirestore.instance
                              .collection('messages')
                              .where('recipientEmail', isEqualTo: user?.email ?? '')
                              .orderBy('timestamp', descending: true),
                          "No inbox messages",
                        ),
                        _buildMessageList(
                          FirebaseFirestore.instance
                              .collection('messages')
                              .where('senderId', isEqualTo: user?.uid ?? '')
                              .where('status', isEqualTo: 'sent')
                              .orderBy('timestamp', descending: true),
                          "No sent messages",
                        ),
                        _buildMessageList(
                          FirebaseFirestore.instance
                              .collection('messages')
                              .where('senderId', isEqualTo: user?.uid ?? '')
                              .where('status', isEqualTo: 'draft')
                              .orderBy('timestamp', descending: true),
                          "No drafts saved",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.create),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComposeMessagePage()),
          );
        },
      ),
    );
  }
}
