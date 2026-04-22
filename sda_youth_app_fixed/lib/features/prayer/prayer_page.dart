import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final _requestController = TextEditingController();

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submitPrayerRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _requestController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a prayer request")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('prayer_requests').add({
      'userId': user.uid,
      'userEmail': user.email,
      'request': _requestController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'supportCount': 0,
    });

    _requestController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prayer request submitted")),
    );
  }

  Future<void> _supportPrayer(DocumentReference ref, int currentCount) async {
    await ref.update({'supportCount': currentCount + 1});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You supported this prayer")),
    );
  }

  Future<void> _deletePrayer(DocumentReference ref) async {
    await ref.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Prayer request deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prayer Requests"), backgroundColor: Colors.teal),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text("Submit a Prayer Request"),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _requestController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Your prayer request",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text("Submit"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: _submitPrayerRequest,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('prayer_requests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No prayer requests yet."));
                }

                final requests = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final prayerDoc = requests[index];
                    final prayer = prayerDoc.data();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer['request'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Submitted by: ${prayer['userEmail'] ?? ''}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.favorite, color: Colors.red),
                                      onPressed: () => _supportPrayer(
                                        prayerDoc.reference,
                                        prayer['supportCount'] ?? 0,
                                      ),
                                    ),
                                    Text("${prayer['supportCount'] ?? 0} supported"),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePrayer(prayerDoc.reference),
                                ),
                              ],
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
    );
  }
}
