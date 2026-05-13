// lib/features/community/feedback_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

/// Feedback Hub — High-fidelity Mission Intelligence Sector.
/// Manages community insights with verified identity metadata stamps.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final _feedbackController = TextEditingController();
  int _rating = 0;
  String _selectedSector = 'App Experience';
  bool _isAnonymous = false;
  bool _isTransmitting = false;

  final List<String> _sectors = ['App Experience', 'Spiritual Content', 'Community Safety', 'Technical Bug'];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleTransmission() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _feedbackController.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _isTransmitting = true);

    try {
      // 1. Fetch Verified Identity Metadata from the Ledger
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String verifiedName = userDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';

      // 2. Transmit Intelligence with verified identity stamp
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.uid,
        'userName': _isAnonymous ? 'Anonymous' : verifiedName,
        'sector': _selectedSector,
        'feedback': text,
        'rating': _rating,
        'isAnonymous': _isAnonymous,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseAnalytics.instance.logEvent(name: 'intelligence_shared');
      
      if (mounted) {
        _feedbackController.clear();
        setState(() { _rating = 0; _isAnonymous = false; });
        _showFeedback("Transmission Received by Mission Control");
        FocusScope.of(context).unfocus();
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    } finally {
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  void _showFeedback(String msg) {
    if (!mounted) return;
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
                    
                    // Intelligence Composer
                    SliverToBoxAdapter(child: _buildIntelligenceCard()),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Text(
                          "COMMUNITY INSIGHT LEDGER",
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),

                    _buildFeedbackStream(),
                    
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("MISSION FEEDBACK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildIntelligenceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SELECT SECTOR", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildSectorSelector(),
          const SizedBox(height: 24),
          
          const Text("YOUR INSIGHT", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "How can we refine the mission experience?",
              hintStyle: const TextStyle(color: Colors.white12),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: accentYellow)),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text("MISSION IMPACT RATING", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          _buildStarRating(),
          
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAnonymityToggle(),
              const Spacer(),
              _buildSubmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectorSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sectors.map((sector) {
        final isSelected = _selectedSector == sector;
        return ChoiceChip(
          label: Text(sector),
          selected: isSelected,
          onSelected: (v) => setState(() => _selectedSector = sector),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: electricTeal,
          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final active = index < _rating;
        return IconButton(
          icon: Icon(active ? Icons.star_rounded : Icons.star_outline_rounded, color: active ? accentYellow : Colors.white12, size: 32),
          onPressed: () => setState(() => _rating = index + 1),
        );
      }),
    );
  }

  Widget _buildAnonymityToggle() {
    return InkWell(
      onTap: () => setState(() => _isAnonymous = !_isAnonymous),
      child: Row(
        children: [
          Icon(_isAnonymous ? Icons.visibility_off : Icons.visibility, color: _isAnonymous ? electricTeal : Colors.white12, size: 18),
          const SizedBox(width: 8),
          Text("ANONYMIZE", style: TextStyle(color: _isAnonymous ? electricTeal : Colors.white12, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isTransmitting ? null : _handleTransmission,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isTransmitting 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text("TRANSMIT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
      ),
    );
  }

  Widget _buildFeedbackStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('feedback').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final docs = snapshot.data!.docs;
        
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final data = docs[index].data();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['sector']?.toUpperCase() ?? 'GENERAL', style: const TextStyle(color: electricTeal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const Spacer(),
                        _buildSmallStars(data['rating'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(data['feedback'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 16),
                    Text(data['userName'] ?? 'Mission Member', style: const TextStyle(color: Colors.white12, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildSmallStars(int count) {
    return Row(
      children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 12, color: i < count ? accentYellow : Colors.white10)),
    );
  }
}
