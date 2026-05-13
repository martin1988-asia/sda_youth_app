// lib/features/messages/notifications_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sda_youth_app/notifications_helper.dart';

/// Notification Center — High-fidelity Alert Control Hub for SDA Youth.
/// Manages real-time FCM transmissions, in-app history, and local reminders.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _notificationsEnabled = true;
  String? _fcmToken;
  TimeOfDay? _selectedTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAlertEngine();
  }

  Future<void> _initializeAlertEngine() async {
    await _initFCM();
    await _loadUserPreference();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _initFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (mounted) setState(() => _fcmToken = token);

        final user = FirebaseAuth.instance.currentUser;
        if (user != null && token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('fcmTokens')
              .doc(token)
              .set({
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
            'platform': kIsWeb ? 'web' : 'mobile',
          }, SetOptions(merge: true));
        }
      }
    } catch (e, st) {
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, st);
    }
  }

  Future<void> _loadUserPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _notificationsEnabled = doc.data()?['notificationsEnabled'] ?? true);
      }
    } catch (_) {}
  }

  Future<void> _toggleAlerts(bool enabled) async {
    setState(() => _notificationsEnabled = enabled);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).set(
        {'notificationsEnabled': enabled, 'lastUpdated': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      if (mounted) _showFeedback(enabled ? "Alert Engine Active" : "Alerts Silenced");
    } catch (_) {}
  }

  Future<void> _scheduleReminder() async {
    if (kIsWeb || _selectedTime == null) return;
    await NotificationsHelper.scheduleDailyReminder(_selectedTime!);
    _showFeedback("Daily Spiritual Reminder Set");
  }

  Future<void> _cancelAll() async {
    if (kIsWeb) return;
    await NotificationsHelper.cancelAllNotifications();
    _showFeedback("Local Queue Cleared");
  }

  void _showFeedback(String msg) {
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
                                
                                _buildSector("System Protocol", [
                                  _switchTile("Identity Notifications", "Global switch for all system alerts", _notificationsEnabled, _toggleAlerts),
                                  _infoTile("Transmission Token", _fcmToken ?? "Detecting...", Icons.vpn_key_outlined),
                                ]),

                                _buildSector("In-App Alert Ledger", [
                                  _buildNotificationStream(),
                                ]),

                                _buildSector("Daily Spiritual Reminder", [
                                  if (kIsWeb)
                                    const Text("Local scheduling managed by OS on Web.", style: TextStyle(color: Colors.white24, fontSize: 12))
                                  else ...[
                                    _actionTile("Select Reminder Time", _selectedTime?.format(context) ?? "Not Scheduled", Icons.access_time_rounded, () async {
                                      final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                      if (picked != null) setState(() => _selectedTime = picked);
                                    }),
                                    const SizedBox(height: 16),
                                    _buildReminderControls(),
                                  ]
                                ]),

                                const SizedBox(height: 100),
                              ],
                            ),
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
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text("WATCHTOWER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
    );
  }

  Widget _buildSector(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("Alert Ledger Clear", style: TextStyle(color: Colors.white24, fontSize: 13));

        return Column(
          children: docs.map((doc) => _buildNotificationItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: electricTeal, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(data['title'] ?? 'System Alert', style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildReminderControls() {
    return Row(
      children: [
        Expanded(child: _miniButton("SCHEDULE", primaryTeal, _scheduleReminder)),
        const SizedBox(width: 12),
        Expanded(child: _miniButton("CANCEL ALL", Colors.white12, _cancelAll)),
      ],
    );
  }

  Widget _miniButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      value: value,
      activeThumbColor: electricTeal,
      activeTrackColor: electricTeal.withValues(alpha: 0.2),
      onChanged: onChanged,
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: primaryTeal, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _actionTile(String label, String value, IconData icon, VoidCallback onTap) {
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            Text(value, style: const TextStyle(color: accentYellow, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
