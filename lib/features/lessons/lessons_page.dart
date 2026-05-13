// lib/features/lessons/lessons_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/lesson_service.dart';
import '../../widgets/titan_shimmer.dart';

/// Lessons Hub — High-fidelity Spiritual Education Sector.
/// Manages community curriculum with real-time enrollment tracking and shimmer-ready synchronization.
class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color premiumBlack = Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator()));

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
          
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    
                    // Study Guidance Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.school_outlined, color: electricTeal.withValues(alpha: 0.1), size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              "MISSION CURRICULUM",
                              style: TextStyle(color: accentYellow, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
                            ),
                            const Text(
                              "Verified spiritual growth through structured community learning.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // The Academy Course Stream
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('lessons') 
                          .orderBy('weekNumber', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // FIXED: Replaced standard spinner with Titan Shimmer skeletons
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const _ShimmerLessonCard(),
                              childCount: 3,
                            ),
                          );
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _AcademyLessonCard(doc: docs[index]),
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
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("DIGITAL ACADEMY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("Academy curriculum is currently synchronizing...", style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AcademyLessonCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);

  const _AcademyLessonCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final weekNum = data['weekNumber']?.toString() ?? '0';
    final title = (data['title'] ?? 'Untitled Mission').toString().toUpperCase();
    final memoryVerse = (data['memoryVerse'] ?? '').toString();
    final summary = (data['summary'] ?? 'Details pending community broadcast.').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _buildWeekBadge(weekNum),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),

          if (memoryVerse.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: electricTeal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: electricTeal.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CORE MEMORY VERSE", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text(
                    memoryVerse,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                
                StreamBuilder<bool>(
                  stream: LessonService.checkEnrollment(doc.id),
                  builder: (context, snapshot) {
                    final bool isEnrolled = snapshot.data ?? false;
                    
                    return Row(
                      children: [
                        _studyButton(
                          isEnrolled ? "RESUME MISSION" : "JOIN ACADEMY", 
                          isEnrolled ? Icons.refresh_rounded : Icons.play_arrow_rounded, 
                          isEnrolled ? Colors.white12 : primaryTeal,
                          () async {
                            if (!isEnrolled) {
                              await LessonService.enrollInCourse(doc.id, title);
                            }
                            if (context.mounted) {
                              context.push('/lessons/${doc.id}');
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.bookmark_outline_rounded, color: Colors.white24),
                          onPressed: () {},
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBadge(String num) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: accentYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentYellow.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text("WEEK", style: TextStyle(color: accentYellow, fontSize: 9, fontWeight: FontWeight.w900)),
          Text(num, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _studyButton(String label, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerLessonCard extends StatelessWidget {
  const _ShimmerLessonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const TitanShimmer.rectangular(height: 50, width: 60),
              const SizedBox(width: 16),
              const Expanded(child: TitanShimmer.rectangular(height: 20)),
            ],
          ),
          const SizedBox(height: 24),
          const TitanShimmer.rectangular(height: 100),
          const SizedBox(height: 24),
          const TitanShimmer.rectangular(height: 48),
        ],
      ),
    );
  }
}
