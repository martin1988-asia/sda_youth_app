import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User updated successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating user: $e")),
      );
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting user: $e")),
      );
    }
  }

  Future<void> _confirmAction(String uid, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $action"),
        content: Text("Are you sure you want to $action this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (action == "delete") {
        await _deleteUser(uid);
      } else if (action == "ban") {
        await _updateUser(uid, {"status": "banned"});
      } else if (action == "makeAdmin") {
        await _updateUser(uid, {"role": "admin"});
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
                title: const Text("Manage Users"),
                backgroundColor: Colors.teal,
              ),
              Expanded(
                child: SafeArea(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search by name, church, or region...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value.toLowerCase()),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance.collection('users').snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text("No users found."));
                                }

                                final users = snapshot.data!.docs.where((doc) {
                                  final data = doc.data();
                                  final name = (data['name'] ?? data['Name'] ?? "")
                                      .toString()
                                      .toLowerCase();
                                  final church = (data['church'] ?? data['Church'] ?? "")
                                      .toString()
                                      .toLowerCase();
                                  final region = (data['region'] ?? data['Region'] ?? "")
                                      .toString()
                                      .toLowerCase();
                                  return name.contains(_searchQuery) ||
                                      church.contains(_searchQuery) ||
                                      region.contains(_searchQuery);
                                }).toList();

                                if (users.isEmpty) {
                                  return const Center(child: Text("No matching users."));
                                }

                                return ListView.builder(
                                  itemCount: users.length,
                                  itemBuilder: (context, index) {
                                    final user = users[index].data();
                                    final uid = users[index].id;
                                    final name = user['name'] ?? user['Name'] ?? uid;
                                    final role = user['role'] ?? 'user';
                                    final status = user['status'] ?? 'active';
                                    final church = user['church'] ?? user['Church'] ?? '';
                                    final region = user['region'] ?? user['Region'] ?? '';
                                    final conference = user['conference'] ?? user['Conference'] ?? '';
                                    final sex = user['sex'] ?? user['Sex'] ?? '';
                                    final language = user['language'] ?? user['Language'] ?? '';
                                    final age = user['age']?.toString() ?? user['Age']?.toString() ?? '';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: user['photoUrl'] != null
                                              ? NetworkImage(user['photoUrl'])
                                              : null,
                                          child: user['photoUrl'] == null
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        title: Text(name),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (church.isNotEmpty) Text("Church: $church"),
                                            if (conference.isNotEmpty) Text("Conference: $conference"),
                                            if (region.isNotEmpty) Text("Region: $region"),
                                            if (sex.isNotEmpty) Text("Sex: $sex"),
                                            if (language.isNotEmpty) Text("Language: $language"),
                                            if (age.isNotEmpty) Text("Age: $age"),
                                            Text("Role: $role"),
                                            Text("Status: $status"),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) => _confirmAction(uid, value),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: "delete",
                                              child: Text("Delete User"),
                                            ),
                                            const PopupMenuItem(
                                              value: "ban",
                                              child: Text("Ban User"),
                                            ),
                                            const PopupMenuItem(
                                              value: "makeAdmin",
                                              child: Text("Make Admin"),
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
