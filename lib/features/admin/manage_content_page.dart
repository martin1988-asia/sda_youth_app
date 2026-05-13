// lib/features/admin/manage_content_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Resource Management Sector — High-fidelity content control for SDA Youth Admins.
class ManageContentPage extends StatefulWidget {
  const ManageContentPage({super.key});

  @override
  State<ManageContentPage> createState() => _ManageContentPageState();
}

class _ManageContentPageState extends State<ManageContentPage> {
  // --- High-Visibility Design Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  String _selectedSector = 'devotionals';

  final List<Map<String, dynamic>> _sectors = [
    {'id': 'devotionals', 'label': 'INSIGHTS', 'icon': Icons.menu_book},
    {'id': 'events', 'label': 'EVENTS', 'icon': Icons.event},
    {'id': 'groups', 'label': 'GROUPS', 'icon': Icons.group},
    {'id': 'community_posts', 'label': 'FEED', 'icon': Icons.forum},
    {'id': 'lessons', 'label': 'LESSONS', 'icon': Icons.school},
    {'id': 'announcements', 'label': 'ALERTS', 'icon': Icons.campaign},
  ];

  Future<void> _deleteItem(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("PURGE RESOURCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Permanently delete this asset from $_selectedSector?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text("CONFIRM DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection(_selectedSector).doc(docId).delete();
        FirebaseAnalytics.instance.logEvent(name: 'admin_content_deleted', parameters: {'sector': _selectedSector});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Asset Purged: $_selectedSector"), backgroundColor: primaryTeal)
          );
        }
      } catch (e, st) {
        if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                // 2. High-Performance Sector Hub
                _buildSectorSelector(),

                // 3. Dynamic Resource Feed
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection(_selectedSector)
                        .orderBy('timestamp', descending: true)
                        .limit(40)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: electricTeal));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) => _buildResourceCard(docs[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorSelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sectors.length,
        itemBuilder: (context, index) {
          final sector = _sectors[index];
          final isSelected = _selectedSector == sector['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(sector['label']),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedSector = sector['id']),
              avatar: Icon(sector['icon'], color: isSelected ? Colors.black : electricTeal, size: 16),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: electricTeal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              showCheckmark: false,
              side: BorderSide(color: isSelected ? electricTeal : Colors.white10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = (data['title'] ?? data['name'] ?? data['authorName'] ?? 'Untitled Resource').toString();
    final subtitle = (data['content'] ?? data['message'] ?? data['description'] ?? 'No metadata available').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            decoration: BoxDecoration(
              color: errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: errorRed, size: 24),
              onPressed: () => _deleteItem(doc.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white.withValues(alpha: 0.05), size: 80),
          const SizedBox(height: 16),
          Text("No items in ${_selectedSector.toUpperCase()}", 
               style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
