// lib/features/events/events_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

/// Event Hub — High-fidelity Community Calendar & Mission Coordination Sector.
/// Manages digital identity gatherings with verified RSVPs and real-time attendance tracking.
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color errorRed = Color(0xFFFF3333);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  DateTime? _selectedDate;
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: electricTeal, 
            surface: Color(0xFF1A1A1A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _publishEvent() async {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty || _selectedDate == null) {
      _showFeedback("Please fulfill all mission fields", isError: true);
      return;
    }

    setState(() => _isPosting = true);
    try {
      final ref = await EventService.broadcastEvent(
        title: title, 
        details: details, 
        date: _selectedDate!
      );

      if (ref != null && mounted) {
        _titleController.clear();
        _detailsController.clear();
        setState(() => _selectedDate = null);
        _showFeedback("Mission Successfully Broadcasted");
        await FirebaseAnalytics.instance.logEvent(name: "event_created");
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    } finally {
      if (mounted) setState(() => _isPosting = false);
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
                    SliverToBoxAdapter(child: _buildEventComposer()),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Text(
                          "UPCOMING MISSIONS",
                          style: TextStyle(color: accentYellow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),
                    _buildMissionStream(),
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
      title: const Text("EVENT HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
    );
  }

  Widget _buildEventComposer() {
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
          const Text("BROADCAST NEW MISSION", style: TextStyle(color: electricTeal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          _inputField(_titleController, "Mission Title", Icons.event_note),
          _inputField(_detailsController, "Gathering Details", Icons.notes, maxLines: 3),
          const SizedBox(height: 12),
          _actionTile(
            _selectedDate == null ? "SELECT MISSION DATE" : DateFormat('EEEE, MMM d, y').format(_selectedDate!),
            Icons.calendar_month_outlined, 
            _pickEventDate
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _publishEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("RELEASE SIGNAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMissionStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: EventService.upcomingMissionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: electricTeal)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildEventCard(docs[index]),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildEventCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final date = (data['date'] as Timestamp).toDate();
    final int attendees = data['participantCount'] ?? 0;
    final bool isOrganizer = data['organizerId'] == FirebaseAuth.instance.currentUser?.uid;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateBlock(date),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['title'] ?? '').toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text(data['details'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 16),
                    _buildOrganizerSign(data['organizerName'] ?? 'Mission Leader', data['organizerPhoto']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAttendanceLabel(attendees),
              const Spacer(),
              _JoinMissionButton(eventId: doc.id),
              if (isOrganizer) 
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white12, size: 20), onPressed: () => EventService.purgeEvent(doc.id)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBlock(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: accentYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentYellow.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(color: accentYellow, fontSize: 10, fontWeight: FontWeight.w900)),
          Text(DateFormat('dd').format(date), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildOrganizerSign(String name, String? photo) {
    return Row(
      children: [
        CircleAvatar(radius: 10, backgroundColor: Colors.white12, backgroundImage: photo != null ? NetworkImage(photo) : null, child: photo == null ? const Icon(Icons.person, size: 10, color: Colors.white38) : null),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(color: electricTeal, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAttendanceLabel(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("JOINING MISSION", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: electricTeal, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
          floatingLabelStyle: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900),
          prefixIcon: Icon(icon, color: primaryTeal, size: 20),
          filled: true,
          fillColor: Colors.black45,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentYellow, width: 2)),
        ),
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Row(
          children: [
            Icon(icon, color: electricTeal, size: 22),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text("No missions scheduled on the horizon.", style: TextStyle(color: Colors.white12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _JoinMissionButton extends StatelessWidget {
  final String eventId;
  const _JoinMissionButton({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: EventService.isAttendingStream(eventId),
      builder: (context, snapshot) {
        final isJoining = snapshot.data ?? false;
        return ElevatedButton(
          onPressed: () => EventService.toggleRsvp(eventId),
          style: ElevatedButton.styleFrom(
            backgroundColor: isJoining ? Colors.white10 : const Color(0xFF00FFCC),
            foregroundColor: isJoining ? Colors.white70 : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isJoining ? 0 : 8,
          ),
          child: Text(isJoining ? "ON MISSION" : "JOIN MISSION", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
        );
      },
    );
  }
}
