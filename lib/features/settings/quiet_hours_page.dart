// lib/features/settings/quiet_hours_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

/// Quiet Hours Sector — High-fidelity Rest Control for SDA Youth.
/// Manages "Digital Sabbath" protocols to ensure uninterrupted focus and rest.
class QuietHoursPage extends StatefulWidget {
  const QuietHoursPage({super.key});

  @override
  State<QuietHoursPage> createState() => _QuietHoursPageState();
}

class _QuietHoursPageState extends State<QuietHoursPage> {
  // --- High-Visibility Branding Palette ---
  static const Color accentYellow = Color(0xFFFFCC00); 
  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color primaryTeal = Color(0xFF008080);
  static const Color premiumBlack = Color(0xFF050505);

  bool _loading = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0); 
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);    
  bool _quietHoursEnabled = false;
  bool _suppressCalls = false;
  bool _suppressMessages = false;

  @override
  void initState() {
    super.initState();
    _loadRestProtocols();
  }

  Future<void> _loadRestProtocols() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _quietHoursEnabled = (data['quietHoursEnabled'] ?? false) == true;
          _suppressCalls = (data['suppressCalls'] ?? false) == true;
          _suppressMessages = (data['suppressMessages'] ?? false) == true;

          final start = data['quietHoursStart']?.toString().split(":");
          final end = data['quietHoursEnd']?.toString().split(":");
          if (start != null && start.length == 2) {
            _startTime = TimeOfDay(
              hour: int.tryParse(start[0]) ?? 22,
              minute: int.tryParse(start[1]) ?? 0,
            );
          }
          if (end != null && end.length == 2) {
            _endTime = TimeOfDay(
              hour: int.tryParse(end[0]) ?? 7,
              minute: int.tryParse(end[1]) ?? 0,
            );
          }
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commitRestProtocols() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    
    String fmt(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance.collection('settings').doc(user.uid).set({
        'quietHoursEnabled': _quietHoursEnabled,
        'quietHoursStart': fmt(_startTime),
        'quietHoursEnd': fmt(_endTime),
        'suppressCalls': _suppressCalls,
        'suppressMessages': _suppressMessages,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Rest Protocols Synchronized");
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showFeedback("Sync Error");
      }
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: electricTeal,
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
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
            child: _loading 
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
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(Icons.nightlight_outlined, color: electricTeal.withValues(alpha: 0.2), size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "DIGITAL SABBATH",
                                  style: TextStyle(color: accentYellow, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                                ),
                                const Text(
                                  "Enforce silence for rest, prayer, and deep focus.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Control Hub
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSector("Activation State", [
                                  _switchTile("Enable Quiet Hours", "Activate rest protocol automatically", _quietHoursEnabled, (v) => setState(() => _quietHoursEnabled = v)),
                                ]),

                                _buildSector("Rest Window", [
                                  _timeTile("Sabbath Start", _startTime.format(context), Icons.nights_stay_outlined, () => _pickTime(true)),
                                  const SizedBox(height: 12),
                                  _timeTile("Sabbath End", _endTime.format(context), Icons.wb_sunny_outlined, () => _pickTime(false)),
                                ]),

                                _buildSector("Disturbance Mitigation", [
                                  _switchTile("Suppress Calls", "Limit incoming audio alerts", _suppressCalls, (v) => setState(() => _suppressCalls = v)),
                                  _switchTile("Suppress Messages", "Silence community DMs", _suppressMessages, (v) => setState(() => _suppressMessages = v)),
                                ]),

                                const SizedBox(height: 32),
                                _buildSaveButton(),
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
        onPressed: () => context.pop(),
      ),
      title: const Text("QUIET HOURS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3)),
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

  Widget _timeTile(String label, String time, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: electricTeal, size: 22),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _loading ? null : _commitRestProtocols,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          shadowColor: primaryTeal.withValues(alpha: 0.4),
        ),
        child: const Text("COMMIT PREFERENCES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
      ),
    );
  }
}
