// lib/features/matchmaking/matchmaking_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/notifications_helper.dart';

/// Matchmaking Hub — High-fidelity Peer Discovery Sector for SDA Youth.
/// Manages identity pairing, mentorship alignment, and community networking.
class MatchmakingPage extends StatefulWidget {
  const MatchmakingPage({super.key});

  @override
  State<MatchmakingPage> createState() => _MatchmakingPageState();
}

class _MatchmakingPageState extends State<MatchmakingPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  bool _mentorshipOptIn = false;
  bool _friendshipOptIn = false;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchmakingRegistry();
  }

  @override
  void dispose() {
    _interestController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchmakingRegistry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('matchmaking')
          .doc('preferences')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _mentorshipOptIn = data['mentorshipOptIn'] ?? false;
          _friendshipOptIn = data['friendshipOptIn'] ?? false;
          _interestController.text = data['interest'] ?? '';
          _regionController.text = data['region'] ?? '';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _commitPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('matchmaking')
          .doc('preferences')
          .set({
        'mentorshipOptIn': _mentorshipOptIn,
        'friendshipOptIn': _friendshipOptIn,
        'interest': _interestController.text.trim(),
        'region': _regionController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAnalytics.instance.logEvent(name: "save_matchmaking_prefs");

      if (mounted) {
        setState(() => _isSaving = false);
        _showFeedback("Synergy Protocols Synchronized");
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleConnect(String targetUid, String targetName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final existing = await FirebaseFirestore.instance
          .collection('connections')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: targetUid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showFeedback("Connection Already Pending", isError: true);
        return;
      }

      // Identity Resolve Logic: Pull verified sender name from Firestore
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String verifiedName = myDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';

      await FirebaseFirestore.instance.collection('connections').add({
        'fromUserId': user.uid,
        'fromUserName': verifiedName,
        'toUserId': targetUid,
        'toUserName': targetName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await NotificationsHelper.sendFriendRequestNotification(
        toUserId: targetUid,
        fromUserId: user.uid,
        fromUserName: verifiedName,
      );

      _showFeedback("Synergy Request Transmitted");
    } catch (e) {
      _showFeedback("Transmission failed", isError: true);
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: electricTeal))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAppBar(),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildSector("Connection Protocols", [
                                  _switchTile("Mentorship Alignment", "Find or become a mission leader", _mentorshipOptIn, (v) => setState(() => _mentorshipOptIn = v)),
                                  _switchTile("Peer Friendship", "Connect with SDA youth peers", _friendshipOptIn, (v) => setState(() => _friendshipOptIn = v)),
                                  const SizedBox(height: 16),
                                  _inputField("Interest Keywords", "e.g. Bible Study, Evangelism", _interestController),
                                  const SizedBox(height: 12),
                                  _inputField("Regional Focus", "e.g. Namibia, Khomas", _regionController),
                                  const SizedBox(height: 24),
                                  _buildSaveButton(),
                                ]),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 30, 24, 16),
                            child: Text(
                              "RECOMMENDED CONNECTIONS",
                              style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                          ),
                        ),

                        _buildSuggestedStream(),

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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/home'),
      ),
      title: const Text("SYNERGY HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
    );
  }

  Widget _buildSector(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSuggestedStream() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('user_lookup').limit(20).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        
        final matches = snapshot.data!.docs
            .where((d) => d.data()['uid'] != myUid)
            .toList();

        if (matches.isEmpty) return _buildEmptyState();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildMatchCard(matches[index]),
            childCount: matches.length,
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final uid = (data['uid'] ?? '').toString();
    final String interest = (data['interest'] ?? 'Faith').toString();
    final String region = (data['region'] ?? 'Global').toString();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? data['displayName'] ?? 'Identity Hidden';
        final photo = userData?['photoURL'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primaryTeal, electricTeal.withValues(alpha: 0.5)]),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: premiumBlack,
                  backgroundImage: photo != null ? NetworkImage(photo.toString()) : null,
                  child: photo == null ? const Icon(Icons.person, color: Colors.white10) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("$interest • $region", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.handshake_outlined, color: electricTeal),
                onPressed: () => _handleConnect(uid, name),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      value: value,
      activeThumbColor: electricTeal,
      activeTrackColor: electricTeal.withValues(alpha: 0.2),
      onChanged: onChanged,
    );
  }

  Widget _inputField(String label, String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: electricTeal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        hintStyle: const TextStyle(color: Colors.white12, fontSize: 12),
        filled: true,
        fillColor: Colors.black45,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _commitPreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: primaryTeal.withValues(alpha: 0.3),
        ),
        child: _isSaving 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text("COMMIT PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("Awaiting new identity records...", style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
