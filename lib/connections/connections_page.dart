// lib/connections/connections_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/notifications_helper.dart';

/// Synergy Ledger — High-fidelity Community Networking Sector for SDA Youth.
/// Manages verified identity pairing through geographic and interest filters.
class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  String? _selectedRegion;
  String? _selectedLanguage;
  String? _selectedSex;
  bool _isProcessing = false;

  final List<String> regions = const [
    'Erongo', 'Khomas', 'Oshana', 'Ohangwena', 'Omusati', 'Oshikoto', 
    'Kavango East', 'Kavango West', 'Zambezi', 'Kunene', 'Otjozondjupa', 
    'Omaheke', 'Hardap', '//Karas'
  ];

  final List<String> languages = const [
    'English', 'Afrikaans', 'Oshiwambo', 'Damara/Nama', 'Herero', 'Other'
  ];

  final List<String> sexes = const ['Male', 'Female', 'Prefer not to say'];

  Future<void> _handleConnect(String targetUid, String targetName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);
    try {
      // 1. Check existing connection ledger
      final existing = await FirebaseFirestore.instance
          .collection('connections')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: targetUid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showFeedback("Synergy Already Requested", isError: true);
        return;
      }

      // 2. Fetch My Verified Metadata for the record
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String myVerifiedName = myDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';

      // 3. Commit Connection with Verified Identity Stamp
      await FirebaseFirestore.instance.collection('connections').add({
        'fromUserId': user.uid,
        'fromUserName': myVerifiedName,
        'toUserId': targetUid,
        'toUserName': targetName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. Transmit Verified Notification
      await NotificationsHelper.sendGeneralNotification(
        userId: targetUid,
        title: "NEW SYNERGY REQUEST",
        body: "$myVerifiedName wants to align with your mission.",
        data: {"route": "/friends"},
      );

      _showFeedback("Connection Signal Transmitted");
      await FirebaseAnalytics.instance.logEvent(name: "synergy_request_sent");
    } catch (e) {
      _showFeedback("Transmission Failed", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: isError ? errorRed : electricTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
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
                    SliverToBoxAdapter(child: _buildFilterHub()),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Text(
                          "POTENTIAL SYNERGIES",
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                      ),
                    ),
                    _buildUserStream(currentUid),
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
      title: const Text("IDENTITY NETWORK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
    );
  }

  Widget _buildFilterHub() {
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
          const Text("NETWORK FILTERS", style: TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildDropdown("GEOGRAPHIC REGION", regions, _selectedRegion, (v) => setState(() => _selectedRegion = v)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDropdown("LANGUAGE", languages, _selectedLanguage, (v) => setState(() => _selectedLanguage = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown("SEX", sexes, _selectedSex, (v) => setState(() => _selectedSex = v))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStream(String? currentUid) {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('user_lookup');

    if (_selectedRegion != null) q = q.where('region', isEqualTo: _selectedRegion);
    // Note: ensure lower-case fields exist in lookup if you want to search by language/sex
    if (_selectedLanguage != null) q = q.where('language', isEqualTo: _selectedLanguage);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.limit(30).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }

        final docs = snapshot.data?.docs.where((d) => d.id != currentUid).toList() ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPeerCard(docs[index]),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildPeerCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['displayName'] ?? 'Verified Identity').toString();
    final church = (data['church'] ?? 'Global Community').toString();
    
    // Identity Halo consistency fix
    final photo = data['photoURL'] ?? data['photoUrl'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [primaryTeal, electricTeal]),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.black,
            backgroundImage: photo != null ? NetworkImage(photo.toString()) : null,
            child: photo == null ? const Icon(Icons.person, color: Colors.white10) : null,
          ),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(church.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        trailing: _isProcessing 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: electricTeal))
          : IconButton(
              icon: const Icon(Icons.handshake_outlined, color: electricTeal, size: 28),
              onPressed: () => _handleConnect(doc.id, name),
            ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xff0e1a2b),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      onChanged: onChanged,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        filled: true,
        fillColor: Colors.black45,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("No identity matches found in this sector.", style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
