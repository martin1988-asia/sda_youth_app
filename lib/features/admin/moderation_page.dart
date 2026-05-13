// lib/features/admin/moderation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sda_youth_app/services/admin_service.dart';

/// Security Sector — High-fidelity moderation queue for SDA Youth.
/// Designed for rapid triage and maximum community protection.
class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC); 
  static const Color primaryTeal = Color(0xFF008080);
  static const Color errorRed = Color(0xFFFF3333);
  static const Color premiumBlack = Color(0xFF050505);

  bool _isProcessing = false;

  Future<void> _processAction(String action, String moderationId, String userId) async {
    final confirmed = await _showConfirmDialog(action);
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      if (action == "dismiss") {
        // Remove incident from the queue
        await FirebaseFirestore.instance.collection('moderation').doc(moderationId).delete();
      } else if (action == "ban") {
        // NUCLEAR OPTION: Terminate Identity across all ledgers via AdminService
        await AdminService.terminateUserIdentity(userId);
        // Also remove the report
        await FirebaseFirestore.instance.collection('moderation').doc(moderationId).delete();
      }

      await FirebaseAnalytics.instance.logEvent(
        name: 'moderation_action_taken',
        parameters: {'action': action, 'target_identity': userId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SECURITY ACTION EXECUTED: ${action.toUpperCase()}"), 
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      if (mounted) _showError("System Error: Protocol interrupted.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: errorRed),
    );
  }

  Future<bool?> _showConfirmDialog(String action) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          action == 'ban' ? "TERMINATE IDENTITY?" : "DISMISS INCIDENT?", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: Text(
          action == "ban" 
            ? "This will execute Protocol Alpha: Erasing this user's digital identity from the SDA Youth ledger permanently. This is logged." 
            : "This will remove the report from the secure queue without taking further action.",
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == "ban" ? errorRed : primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("SECURITY QUEUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
      ),
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('moderation')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: electricTeal));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => _buildIncidentCard(docs[index]),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final userId = (data['userId'] ?? data['targetUserId'] ?? 'Anonymous Identity').toString();
    final reason = (data['reason'] ?? 'Flagged by community filter').toString();
    final type = (data['type'] ?? 'General Violation').toString();
    final ts = data['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: errorRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_maybe, color: errorRed, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userId.toUpperCase(), 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                    ),
                    Text(
                      ts != null ? timeago.format(ts.toDate()) : "PENDING REVIEW", 
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _buildTypeBadge(type),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            reason, 
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: "DISMISS", 
                  color: Colors.white.withValues(alpha: 0.05), 
                  textColor: Colors.white70,
                  onTap: () => _processAction("dismiss", doc.id, userId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  label: "TERMINATE", 
                  color: errorRed.withValues(alpha: 0.8), 
                  textColor: Colors.white,
                  onTap: () => _processAction("ban", doc.id, userId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentYellow.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentYellow.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(), 
        style: const TextStyle(color: accentYellow, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isProcessing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(
              label, 
              style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, color: electricTeal.withValues(alpha: 0.1), size: 100),
          const SizedBox(height: 20),
          const Text(
            "COMMUNITY SECURED", 
            style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
          ),
          const Text(
            "No pending threats found in the security queue.", 
            style: TextStyle(color: Colors.white10, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
