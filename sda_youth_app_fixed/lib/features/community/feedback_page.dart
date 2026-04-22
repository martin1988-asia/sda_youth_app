import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _feedbackController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _feedbackController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter feedback before submitting")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': user.uid,
      'feedback': _feedbackController.text.trim(),
      'rating': _rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _feedbackController.clear();
    setState(() => _rating = 0);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thank you for your feedback!")),
    );
  }

  Future<void> _deleteFeedback(String docId) async {
    await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback deleted")),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => setState(() => _rating = index + 1),
        );
      }),
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
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    AppBar(
                      title: const Text("Feedback"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We value your feedback!",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Your Feedback",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Rate the App"),
                    _buildRatingStars(),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text("Submit Feedback"),
                      onPressed: _submitFeedback,
                    ),
                    const Divider(height: 40),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('feedback')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No feedback yet."));
                          }

                          final feedbackList = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: feedbackList.length,
                            itemBuilder: (context, index) {
                              final fbDoc = feedbackList[index];
                              final fb = fbDoc.data();
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.star,
                                    color: (fb['rating'] ?? 0) > 0 ? Colors.amber : Colors.grey,
                                  ),
                                  title: Text(fb['feedback'] ?? ''),
                                  subtitle: Text(
                                    "Rating: ${fb['rating'] ?? 0} • ${fb['timestamp']?.toString() ?? ''}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteFeedback(fbDoc.id),
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
        ],
      ),
    );
  }
}
