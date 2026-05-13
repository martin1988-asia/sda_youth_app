// lib/features/community/support_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Support Hub — High-fidelity Administrative Assistance Sector.
/// Manages community help requests with optimized layouts and refined action triggers.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final _msgController = TextEditingController();
  bool _isTransmitting = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _handleSupportRequest() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTransmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final String verifiedName = userDoc.data()?['name'] ?? user.displayName ?? 'Mission Member';

      await FirebaseFirestore.instance.collection('support').add({
        'userId': user.uid,
        'userName': verifiedName,
        'email': user.email,
        'message': text,
        'status': 'open',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseAnalytics.instance.logEvent(name: 'support_ticket_created');

      if (mounted) {
        _msgController.clear();
        _showFeedback("Support Ticket Logged & Verified");
        context.pop();
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
      _showFeedback("Transmission Error", isError: true);
    } finally {
      if (mounted) setState(() => _isTransmitting = false);
    }
  }

  Future<void> _launchCommunication(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showFeedback("System cannot initialize link", isError: true);
      }
    } catch (e) {
      _showFeedback("Communication Link Interrupted", isError: true);
    }
  }

  void _showFeedback(String msg, {bool isError = false}) {
    if (!mounted) return;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text("SUPPORT CENTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
      ),
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
                constraints: const BoxConstraints(maxWidth: 550), // Optimized for readability
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 24),
                      _buildTicketComposer(),
                      const SizedBox(height: 32),
                      _buildQuickContactSector(),
                      const SizedBox(height: 32),
                      _buildAboutSector(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: electricTeal.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: electricTeal, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SYSTEM OPERATIONAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                SizedBox(height: 2),
                Text("Mission sectors performing at peak fidelity.", style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketComposer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("INITIALIZE HELP SIGNAL", style: TextStyle(color: accentYellow, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          TextField(
            controller: _msgController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Describe the mission blocker...",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: Colors.black38,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 180, // Optimized shorter button length
              height: 48,
              child: ElevatedButton(
                onPressed: _isTransmitting ? null : _handleSupportRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isTransmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("TRANSMIT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactSector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 12),
          child: Text("DIRECT CHANNELS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        // Changed to Midnight Teal for better visibility as requested
        _contactTile(Icons.alternate_email_rounded, "Electronic Mail", "mbweti@gmail.com", () => _launchCommunication("mailto:mbweti@gmail.com")),
        _contactTile(Icons.phone_iphone_rounded, "Identity Voice", "+264 81 312 6137", () => _launchCommunication("tel:+264813126137")),
      ],
    );
  }

  Widget _contactTile(IconData icon, String label, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A1E), // Distinct Midnight Teal background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: accentYellow, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white10, size: 14),
      ),
    );
  }

  Widget _buildAboutSector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("VERSION", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              Text("1.0.0 ALPHA", style: TextStyle(color: electricTeal.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("LEAD DEVELOPER", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              const Text("MARTIN", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
