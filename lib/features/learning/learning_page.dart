import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  Future<void> _enrollCourse(String courseId) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrollments')
        .doc(courseId)
        .set({
      'enrolledAt': FieldValue.serverTimestamp(),
      'progress': 0,
    });
    messenger.showSnackBar(const SnackBar(content: Text("Enrolled successfully")));
  }

  Future<void> _updateProgress(String courseId, int increment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrollments')
        .doc(courseId);

    final doc = await ref.get();
    int current = doc.exists ? (doc.data()?['progress'] ?? 0) : 0;
    await ref.set({'progress': current + increment}, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Progress updated: +$increment points")),
    );
  }

  Future<void> _submitQuiz(String courseId, int score) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('quizzes')
        .add({
      'courseId': courseId,
      'score': score,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await _updateProgress(courseId, score);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Quiz submitted: $score points earned")),
    );
  }

  Widget _quizSection(String courseId) {
    final answerController = TextEditingController();
    return ExpansionTile(
      title: const Text("Practice Quiz"),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const Text(
                "Sample Question: What is the first book of the Bible?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  hintText: "Your answer",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Submit Answer"),
                onPressed: () {
                  final answer = answerController.text.trim().toLowerCase();
                  int score = (answer == "genesis") ? 10 : 0;
                  _submitQuiz(courseId, score);
                  answerController.clear();
                },
              ),
            ],
          ),
        ),
      ],
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
          Column(
            children: [
              AppBar(title: const Text("Learning Hub"), backgroundColor: Colors.teal),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No courses available."));
                    }

                    final courses = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final courseDoc = courses[index];
                        final course = courseDoc.data();
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course['description'] ?? '',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                Text(
                                  "Duration: ${course['duration'] ?? 'N/A'}",
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.school),
                                  label: const Text("Enroll"),
                                  onPressed: () => _enrollCourse(courseDoc.id),
                                ),
                                const Divider(),
                                _quizSection(courseDoc.id),
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
