// lib/features/devotionals/devotionals_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/services/devotional_service.dart';

/// Devotionals Hub — High-fidelity Spiritual Nourishment Sector.
/// Manages daily insights and verified community reflections with growth tracking.
class DevotionalsPage extends StatefulWidget {
  const DevotionalsPage({super.key});

  @override
  State<DevotionalsPage> createState() => _DevotionalsPageState();
}

class _DevotionalsPageState extends State<DevotionalsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final _titleController = TextEditingController();
  final _verseController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isAdmin = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final role = await RoleService.getAuthorizedRole();
    if (mounted) {
      setState(() => _isAdmin = (role.name == 'admin' || role.name == 'editor'));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _verseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _publishDevotional() async {
    final title = _titleController.text.trim();
    final verse = _verseController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
       _showFeedback("Please fulfill all identity fields", isError: true);
       return;
    }
    
    setState(() => _isPosting = true);
    try {
      final ref = await DevotionalService.broadcastManna(
        title: title, 
        verse: verse, 
        message: message
      );
      if (ref != null) {
        _titleController.clear();
        _verseController.clear();
        _messageController.clear();
        _showFeedback("Spiritual Insight Transmitted");
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? Colors.redAccent : electricTeal,
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
                    if (_isAdmin) SliverToBoxAdapter(child: _buildAdminComposer()),
                    _buildMannaStream(),
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
      title: const Text("DAILY MANNA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      actions: [
        IconButton(
          icon: const Icon(Icons.stars_rounded, color: accentYellow),
          onPressed: () => context.push('/favorites'),
        ),
      ],
    );
  }

  Widget _buildMannaStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DevotionalService.mannaStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _DevotionalCard(doc: docs[index]),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildAdminComposer() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Text("PUBLISH SPIRITUAL INSIGHT", style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          _miniField(_titleController, "Insight Title"),
          _miniField(_verseController, "Scripture Reference"),
          _miniField(_messageController, "Devotional Message", maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _publishDevotional,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("RELEASE TO COMMUNITY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _miniField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          filled: true,
          fillColor: Colors.black38,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("Awaiting tomorrow's Manna...", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DevotionalCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);

  const _DevotionalCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title'] ?? 'Daily Insight';
    final verse = data['verse'] ?? '';
    final message = data['message'] ?? '';
    final ts = data['date'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ts != null ? timeago.format(ts.toDate()).toUpperCase() : "RECENT", 
                style: const TextStyle(color: electricTeal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              _FavoriteToggle(devotionalId: doc.id, title: title),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(verse, style: const TextStyle(color: accentYellow, fontSize: 15, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          _ReflectionEngine(devotionalId: doc.id),
        ],
      ),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  final String devotionalId;
  final String title;
  const _FavoriteToggle({required this.devotionalId, required this.title});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: DevotionalService.isFavoritedStream(devotionalId),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return IconButton(
          icon: Icon(isFav ? Icons.star_rounded : Icons.star_outline_rounded, color: isFav ? const Color(0xFFFFCC00) : Colors.white10),
          onPressed: () => DevotionalService.toggleFavorite(devotionalId, title),
        );
      },
    );
  }
}

class _ReflectionEngine extends StatefulWidget {
  final String devotionalId;
  const _ReflectionEngine({required this.devotionalId});

  @override
  State<_ReflectionEngine> createState() => _ReflectionEngineState();
}

class _ReflectionEngineState extends State<_ReflectionEngine> {
  final _ctrl = TextEditingController();
  bool _isSending = false;

  Future<void> _submitReflection() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    await DevotionalService.transmitReflection(devotionalId: widget.devotionalId, text: text);
    _ctrl.clear();
    if (mounted) {
      setState(() => _isSending = false);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Reflect on this wisdom...",
            hintStyle: const TextStyle(color: Colors.white10),
            suffixIcon: _isSending 
              ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white12)))
              : IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFF00FFCC), size: 18), onPressed: _submitReflection),
            border: InputBorder.none,
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('devotionals').doc(widget.devotionalId).collection('reflections').orderBy('timestamp', descending: true).limit(3).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            return Column(
              children: docs.map((d) {
                final data = d.data();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14, 
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    backgroundImage: data['userPhoto'] != null ? NetworkImage(data['userPhoto']) : null,
                    child: data['userPhoto'] == null ? const Icon(Icons.person, size: 14, color: Colors.white24) : null,
                  ),
                  title: Text(data['reflection'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  subtitle: Text(data['userName'] ?? 'Member', style: const TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }
}
