import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareReelPage extends StatelessWidget {
  final String reelId;

  const ShareReelPage({super.key, required this.reelId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not authenticated")),
      );
    }

    final currentUserId = currentUser.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Send Reel"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No users found",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final userDoc = users[i];
              final data = userDoc.data();

              final uid = userDoc.id;

              // ✅ skip current user
              if (uid == currentUserId) {
                return const SizedBox();
              }

              final name = data['name'] ?? 'User';
              final photo = data['userPhotoUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white12,
                  backgroundImage: (photo != null &&
                          photo.toString().startsWith("http"))
                      ? NetworkImage(photo)
                      : null,
                  child: photo == null
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                title: Text(
                  name,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await _sendReelToUser(
                    currentUserId: currentUserId,
                    otherUserId: uid,
                    reelId: reelId,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // close page after sending
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reel sent ✅"),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // ✅ ✅ CORE LOGIC (PRODUCTION SAFE)
  Future<void> _sendReelToUser({
    required String currentUserId,
    required String otherUserId,
    required String reelId,
  }) async {
    final ids = [currentUserId, otherUserId]..sort();
    final chatId = "${ids[0]}_${ids[1]}";

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    // ✅ CREATE / UPDATE CHAT
    await chatRef.set({
      'participants': ids,
      'lastMessage': "🎬 Reel",
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ ADD MESSAGE (REEL TYPE)
    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'receiverId': otherUserId,
      'type': 'reel', // ✅ important (new type)
      'reelId': reelId,
      'text': null,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
