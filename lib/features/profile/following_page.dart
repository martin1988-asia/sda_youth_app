import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowingPage extends StatelessWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Following"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('following')
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
            itemBuilder: (_, index) {
              return ListTile(
                title: Text(
                  users[index].id,
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
