import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComposeMessagePage extends StatefulWidget {
  const ComposeMessagePage({super.key});

  @override
  State<ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<ComposeMessagePage> {
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _saveMessage({bool draft = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _messageController.text.trim().isEmpty ||
        _recipientController.text.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('messages').add({
      'text': _messageController.text.trim(),
      'senderId': user.uid,
      'senderEmail': user.email,
      'recipientEmail': _recipientController.text.trim(),
      'status': draft ? 'draft' : 'sent',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    _messageController.clear();
    _recipientController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(draft ? "Draft saved" : "Message sent")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Compose Message"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)), // ✅ fixed
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6), // ✅ polished
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset('assets/sda_logo.png', height: 60),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _recipientController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Recipient Email",
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        maxLines: 6,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Message",
                          labelStyle: TextStyle(color: Colors.white),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text("Save Draft"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _saveMessage(draft: true),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text("Send"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _saveMessage(draft: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
