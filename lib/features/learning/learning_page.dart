// lib/features/learning/learning_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Learning Hub — World-class Spiritual Academy for SDA Youth.
/// Manages curriculum tracks, interactive assessments, and identity growth metrics.
class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _isProcessing = false;

  Future<void> _enrollInTrack(String courseId, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(courseId)
          .set({
        'courseTitle': title,
        'enrolledAt': FieldValue.serverTimestamp(),
        'progress': 0, // Percentage 0-100
      }, SetOptions(merge: true));

      if (mounted) _showFeedback("Mission Track: $title Initialized");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Verification Required")));

    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
          // 1. Cinematic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    
                    // 2. Growth Snapshot Sector
                    SliverToBoxAdapter(child: _buildAcademyHeader()),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 30, 24, 12),
                        child: Text(
                          "AVAILABLE TRACKS",
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),

                    // 3. The Curriculum Stream
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildCourseCard(docs[index], user.uid),
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("ACADEMY HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
    );
  }

  Widget _buildAcademyHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: accentYellow, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SPIRITUAL GROWTH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text("Expand your mission through structured study.", style: TextStyle(color: electricTeal.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, String uid) {
    final data = doc.data();
    final title = (data['title'] ?? 'Untitled Track').toString().toUpperCase();
    final desc = (data['description'] ?? 'No track metadata available.').toString();
    final duration = (data['duration'] ?? 'Self-Paced').toString();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('enrollments').doc(doc.id).snapshots(),
      builder: (context, enrollSnap) {
        final enrolled = enrollSnap.hasData && enrollSnap.data!.exists;
        final int progress = enrollSnap.data?.data()?['progress'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTypeBadge(data['category'] ?? "General"),
                        Text(duration, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 24),
                    
                    if (enrolled) _buildProgressBar(progress) else _buildEnrollButton(doc.id, title),
                  ],
                ),
              ),
              if (enrolled) _QuizStudio(courseId: doc.id),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTypeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: electricTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: electricTeal.withValues(alpha: 0.2)),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(color: electricTeal, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildProgressBar(int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("MISSION PROGRESS", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text("$progress%", style: const TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 6,
            backgroundColor: Colors.white10,
            color: electricTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollButton(String id, String title) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _enrollInTrack(id, title),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text("INITIALIZE TRACK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("Awaiting new Mission Tracks...", style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _QuizStudio extends StatefulWidget {
  final String courseId;
  const _QuizStudio({required this.courseId});

  @override
  State<_QuizStudio> createState() => _QuizStudioState();
}

class _QuizStudioState extends State<_QuizStudio> {
  final _ctrl = TextEditingController();

  Future<void> _submitAssessment() async {
    final text = _ctrl.text.trim().toLowerCase();
    if (text.isEmpty) return;

    int score = (text == "genesis") ? 20 : 5; // Logic matched to your original version
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quizzes')
          .add({
        'courseId': widget.courseId,
        'score': score,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Atomic increment progress
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrollments')
          .doc(widget.courseId)
          .update({'progress': FieldValue.increment(5)});
    }

    _ctrl.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Knowledge Verified: Progress Updated")));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("KNOWLEDGE CHECK", style: TextStyle(color: Color(0xFFFFCC00), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          const Text("What is the first book of the Bible?", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Enter response...",
              hintStyle: const TextStyle(color: Colors.white12),
              suffixIcon: IconButton(icon: const Icon(Icons.verified_outlined, color: Color(0xFF00FFCC)), onPressed: _submitAssessment),
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
