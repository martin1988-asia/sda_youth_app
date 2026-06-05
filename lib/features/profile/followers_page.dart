import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowersPage extends StatelessWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Followers"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('followers')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              return ListTile(
                title: Text(
                  users[i].id,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
