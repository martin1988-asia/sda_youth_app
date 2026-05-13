// lib/features/messages/compose_message_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/services/message_service.dart';

/// Compose Message Sector — High-fidelity Communication for SDA Youth.
/// Manages identity-based member discovery and secure transmission initialization.
class ComposeMessagePage extends StatefulWidget {
  const ComposeMessagePage({super.key});

  @override
  State<ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<ComposeMessagePage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  
  // Stores verified identity metadata for discovery
  final List<Map<String, dynamic>> _recipientOptions = <Map<String, dynamic>>[];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  /// High-fidelity Identity Discovery logic.
  /// Searches by verified Name or Username in the community ledger.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final term = query.trim();
      if (term.isEmpty) {
        if (mounted) setState(() => _recipientOptions.clear());
        return;
      }

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: term)
            .where('name', isLessThanOrEqualTo: '$term\uf8ff')
            .limit(5)
            .get();

        final results = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['name'] ?? 'Mission Member',
            'email': data['email'] ?? '',
            'photo': data['photoURL'],
          };
        }).toList();

        if (mounted) {
          setState(() {
            _recipientOptions.clear();
            _recipientOptions.addAll(results);
          });
        }
      } catch (e, stack) {
        if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      }
    });
  }

  Future<void> _transmitMessage({required bool isDraft}) async {
    final user = FirebaseAuth.instance.currentUser;
    final recipientEmail = _recipientController.text.trim();
    final messageText = _messageController.text.trim();

    if (user == null || messageText.isEmpty || (!isDraft && recipientEmail.isEmpty)) {
      _showFeedback("Required Fields Missing", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await MessageService.sendMessage(
        text: messageText,
        recipientEmail: recipientEmail,
        draft: isDraft,
      );

      await FirebaseAnalytics.instance.logEvent(
        name: isDraft ? "draft_saved" : "message_transmitted",
        parameters: {"identity": user.uid},
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showFeedback(isDraft ? "Draft Encrypted & Saved" : "Transmission Successful");
        context.pop();
      }
    } catch (e, stack) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
      if (mounted) {
        setState(() => _isLoading = false);
        _showFeedback("Identity synchronization failed", isError: true);
      }
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
                constraints: const BoxConstraints(maxWidth: 600),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: _buildComposeHub(),
                      ),
                    ),
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
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text("NEW TRANSMISSION", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildComposeHub() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecipientField(),
          const SizedBox(height: 24),
          _buildMessageField(),
          const SizedBox(height: 40),
          _buildActionDock(),
        ],
      ),
    );
  }

  Widget _buildRecipientField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("RECIPIENT IDENTITY", 
          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) => option['email'] as String,
          optionsBuilder: (TextEditingValue value) {
            _onSearchChanged(value.text);
            return _recipientOptions;
          },
          onSelected: (selection) => _recipientController.text = selection['email'],
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: _inputDecoration("SEARCH NAME OR USERNAME", Icons.person_search_outlined),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final String name = option['name'] ?? 'Mission Member';
                      final String email = option['email'] ?? '';
                      final String? photo = option['photo'];

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: primaryTeal,
                          backgroundImage: photo != null ? NetworkImage(photo) : null,
                          child: photo == null ? const Icon(Icons.person, size: 16, color: Colors.white30) : null,
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(email, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MESSAGE METADATA", 
          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          maxLines: 6,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: _inputDecoration("WHAT'S ON YOUR HEART?", Icons.chat_bubble_outline),
        ),
      ],
    );
  }

  Widget _buildActionDock() {
    return Row(
      children: [
        Expanded(
          child: _button(
            "SAVE DRAFT", 
            Colors.white12, 
            Colors.white70, 
            () => _transmitMessage(isDraft: true)
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _button(
            "TRANSMIT", 
            primaryTeal, 
            Colors.white, 
            () => _transmitMessage(isDraft: false)
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1),
      floatingLabelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: primaryTeal, size: 20),
      filled: true,
      fillColor: Colors.black45,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: electricTeal, width: 2)),
    );
  }

  Widget _button(String label, Color color, Color textColor, VoidCallback onTap) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
      ),
    );
  }
}
