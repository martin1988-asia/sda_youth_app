// lib/features/lessons/lesson_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/services/lesson_service.dart';
import 'package:sda_youth_app/services/gamification_service.dart';

/// Lesson Detail Terminal — High-fidelity Study Environment.
/// Manages immersive content consumption and verified academic progress.
class LessonDetailPage extends StatefulWidget {
  final String lessonId;
  const LessonDetailPage({super.key, required this.lessonId});

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _isCompleting = false;

  Future<void> _handleCompletion(String title) async {
    setState(() => _isCompleting = true);
    try {
      // 1. Sync Progress to Academy Ledger
      await LessonService.updateProgress(
        courseId: widget.lessonId, 
        progress: 1.0, 
        finished: true
      );

      // 2. Award Kingdom XP (50 XP for Lesson Completion)
      await GamificationService.awardXp(50, "Completed Mission: $title");

      if (mounted) {
        _showVictorySnack(title);
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void _showVictorySnack(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MISSION ACCOMPLISHED", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 2, fontSize: 10)),
            Text("$title Digested", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('lessons').doc(widget.lessonId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator(color: electricTeal)));
        
        final data = snapshot.data!.data() ?? {};
        final String title = data['title'] ?? 'Untitled Mission';
        final String content = data['content'] ?? 'Transmission details pending...';
        final String verse = data['memoryVerse'] ?? '';

        return Scaffold(
          backgroundColor: premiumBlack,
          body: Stack(
            children: [
              // Cinematic Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff0e1a2b), Color(0xFF050505)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(title),
                  
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStudyHeader(title, verse),
                              const SizedBox(height: 32),
                              Text(
                                content,
                                style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.8, letterSpacing: 0.2),
                              ),
                              const SizedBox(height: 40),
                              _buildCompletionButton(title),
                              const SizedBox(height: 100),
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
      },
    );
  }

  Widget _buildAppBar(String title) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white24), onPressed: () {}),
      ],
    );
  }

  Widget _buildStudyHeader(String title, String verse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ACADEMY MISSION", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 8),
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        if (verse.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentYellow.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentYellow.withValues(alpha: 0.1)),
            ),
            child: Text(
              verse,
              style: const TextStyle(color: accentYellow, fontSize: 15, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionButton(String title) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isCompleting ? null : () => _handleCompletion(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          shadowColor: primaryTeal.withValues(alpha: 0.4),
        ),
        child: _isCompleting 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("COMPLETE MISSION (+50 XP)", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }
}
