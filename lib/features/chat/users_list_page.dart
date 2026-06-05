import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../messages/chat_thread_page.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = "";

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("New Message"),
      ),

      body: Column(
        children: [
          // ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) {
                  setState(() => _search = v.toLowerCase());
                },
                decoration: const InputDecoration(
                  hintText: "Search users...",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // ✅ USERS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
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

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),

                  itemBuilder: (_, i) {
                    final data = users[i].data() as Map<String, dynamic>;
                    final uid = users[i].id;

                    if (uid == currentUid) {
                      return const SizedBox();
                    }

                    final String name = (data['name'] ?? "User").toString();

                    final String? photo = data['photoUrl']?.toString();

                    // ✅ SEARCH FILTER
                    if (_search.isNotEmpty &&
                        !name.toLowerCase().contains(_search)) {
                      return const SizedBox();
                    }

                    return _UserTile(uid: uid, name: name, photo: photo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String uid;
  final String name;
  final String? photo;

  const _UserTile({required this.uid, required this.name, required this.photo});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null && photo!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatThreadPage(otherUserId: uid)),
        );
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [
            // ✅ AVATAR (FIXED NULL SAFE)
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[800],
              backgroundImage: hasPhoto ? NetworkImage(photo!) : null,
              child: !hasPhoto
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 14),

            // ✅ TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Tap to start chat",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}
