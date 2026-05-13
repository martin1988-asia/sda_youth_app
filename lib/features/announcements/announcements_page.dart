// lib/features/announcements/announcements_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/services/announcement_service.dart';
import 'package:sda_youth_app/core/user_role.dart';

/// Announcements Hub — High-fidelity Mission Broadcast Sector.
/// Manages official community alerts with real-time urgency and verified authority.
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC); 
  static const Color premiumBlack = Color(0xFF050505);
  static const Color alertRed = Color(0xFFFF3333);

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkClearance();
  }

  Future<void> _checkClearance() async {
    final role = await RoleService.getUserRole();
    if (mounted) {
      setState(() => _isAdmin = (role == UserRole.admin || role == UserRole.moderator));
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logEvent(name: 'view_bulletin_hub');

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
                    _buildAppBar(context),
                    
                    // 2. Sovereign Command Sector (Admin Only)
                    if (_isAdmin) SliverToBoxAdapter(child: _AdminBroadcastPanel()),

                    // 3. Official Broadcast Stream
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: AnnouncementService.announcementsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator(color: electricTeal)),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildAlertCard(docs[index]),
                            childCount: docs.length,
                          ),
                        );
                      },
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        "MISSION BULLETIN", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16),
      ),
    );
  }

  Widget _buildAlertCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] ?? 'Official Transmission').toString();
    final message = (data['message'] ?? '').toString();
    final category = (data['category'] ?? 'Update').toString();
    final ts = data['timestamp'] as Timestamp?;
    final String author = data['authorName'] ?? 'Mission Control';

    Color categoryColor = electricTeal;
    if (category.toLowerCase() == 'urgent') categoryColor = alertRed;
    if (category.toLowerCase() == 'inspiration') categoryColor = accentYellow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: categoryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryBadge(category, categoryColor),
              Text(
                ts != null ? timeago.format(ts.toDate()).toUpperCase() : "LIVE",
                style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message, 
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: categoryColor.withValues(alpha: 0.5), size: 14),
              const SizedBox(width: 8),
              Text(
                author.toUpperCase(),
                style: const TextStyle(color: Colors.white12, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const Spacer(),
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white12, size: 20),
                  onPressed: () => AnnouncementService.purgeBroadcast(doc.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, color: Colors.white10, size: 80),
            SizedBox(height: 16),
            Text("NO BROADCASTS FOUND", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

class _AdminBroadcastPanel extends StatefulWidget {
  @override
  State<_AdminBroadcastPanel> createState() => _AdminBroadcastPanelState();
}

class _AdminBroadcastPanelState extends State<_AdminBroadcastPanel> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _category = 'Update';
  bool _isBroadcasting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SOVEREIGN BROADCAST UNIT", style: TextStyle(color: Color(0xFFFFCC00), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          _inputField(_titleCtrl, "Transmission Title"),
          _inputField(_msgCtrl, "Broadcast Message", maxLines: 3),
          const SizedBox(height: 12),
          Row(
            children: ['Urgent', 'Update', 'Inspiration'].map((cat) {
              final isSel = _category == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat.toUpperCase()),
                  selected: isSel,
                  onSelected: (v) => setState(() => _category = cat),
                  selectedColor: const Color(0xFF00FFCC),
                  backgroundColor: Colors.white10,
                  labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _isBroadcasting ? null : () async {
                if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
                setState(() => _isBroadcasting = true);
                await AnnouncementService.broadcast(title: _titleCtrl.text, message: _msgCtrl.text, category: _category);
                _titleCtrl.clear(); _msgCtrl.clear();
                if (mounted) setState(() => _isBroadcasting = false);
              },
              child: _isBroadcasting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("INITIALIZE BROADCAST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white10),
          filled: true,
          fillColor: Colors.black38,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
