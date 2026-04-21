import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications_helper.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _sendFriendRequest(String toUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'fromUserId': user.uid,
        'toUserId': toUserId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔔 Send notification to recipient
      await NotificationsHelper.sendFriendRequestNotification(
        toUserId: toUserId,
        fromUserId: user.uid,
        fromUserName: user.email ?? "Unknown",
      );

      if (!mounted) return; // ✅ check right before context use
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request sent")),
      );
    } catch (e) {
      if (!mounted) return; // ✅ check right before context use
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending request: $e")),
      );
    }
  }

  Future<void> _acceptRequest(String requestId, String fromUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Add to friends collection for both users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .doc(fromUserId)
          .set({
        'friendId': fromUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(user.uid)
          .set({
        'friendId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔔 Notify the sender
      await NotificationsHelper.sendGeneralNotification(
        userId: fromUserId,
        title: "Friend Request Accepted",
        body: "${user.email} accepted your friend request",
      );

      if (!mounted) return; // ✅ check right before context use
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request accepted")),
      );
    } catch (e) {
      if (!mounted) return; // ✅ check right before context use
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting request: $e")),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      if (!mounted) return; // ✅ check right before context use
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request rejected")),
      );
    } catch (e) {
      if (!mounted) return; // ✅ check right before context use
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error rejecting request: $e")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search users by email",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (val) async {
                if (val.trim().isEmpty) return;
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: val.trim())
                    .get();
                if (query.docs.isNotEmpty) {
                  final toUserId = query.docs.first.id;
                  _sendFriendRequest(toUserId);
                } else {
                  if (!mounted) return; // ✅ check right before context use
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User not found")),
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Pending requests
            const Text(
              "Pending Requests",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('friend_requests')
                    .where('toUserId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final requests = snapshot.data!.docs;
                  return ListView(
                    children: requests.map((req) {
                      final data = req.data();
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_add),
                          title: Text("Request from ${data['fromUserId']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () =>
                                    _acceptRequest(req.id, data['fromUserId']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectRequest(req.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Friends list
            const Text(
              "My Friends",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('friends')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final friends = snapshot.data!.docs;
                  return ListView(
                    children: friends.map((f) {
                      final fData = f.data();
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.teal),
                          title: Text("Friend: ${fData['friendId']}"),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
