// lib/features/admin/moderation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sda_youth_app/services/security_queue_service.dart';
import 'package:sda_youth_app/features/admin/security_logs_page.dart';
import 'package:sda_youth_app/features/admin/add_incident_page.dart';

// Colors (adjust to your theme)
const premiumBlack = Color(0xFF050505);
const errorRed = Color(0xFFFF3333);
const accentYellow = Color(0xFFFFCC00);
const electricTeal = Color(0xFF00FFCC);
const primaryTeal = Color(0xFF00FFCC);

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  String _selectedSeverity = 'All';
  String _selectedType = 'All';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: premiumBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "SECURITY QUEUE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "View Security Logs",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SecurityLogsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSeverity, // fixed
                    dropdownColor: premiumBlack,
                    style: const TextStyle(color: Colors.white),
                    items: ['All', 'Low', 'Medium', 'High']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSeverity = val ?? 'All'),
                    decoration: const InputDecoration(
                      labelText: "Severity",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType, // fixed
                    dropdownColor: premiumBlack,
                    style: const TextStyle(color: Colors.white),
                    items: ['All', 'General Violation', 'Spam', 'Harassment']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedType = val ?? 'All'),
                    decoration: const InputDecoration(
                      labelText: "Type",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Quick status toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("All"),
                  selected: _statusFilter == 'All',
                  onSelected: (_) => setState(() => _statusFilter = 'All'),
                  selectedColor: primaryTeal,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Pending"),
                  selected: _statusFilter == 'Pending',
                  onSelected: (_) => setState(() => _statusFilter = 'Pending'),
                  selectedColor: accentYellow,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Resolved"),
                  selected: _statusFilter == 'Resolved',
                  onSelected: (_) => setState(() => _statusFilter = 'Resolved'),
                  selectedColor: Colors.greenAccent,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('moderation')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryTeal),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                var filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final severity = (data['severity'] ?? 'Medium').toString();
                  final type = (data['type'] ?? 'General Violation').toString();
                  final status = (data['status'] ?? 'Pending').toString();

                  final severityMatch =
                      _selectedSeverity == 'All' ||
                      severity.toLowerCase() == _selectedSeverity.toLowerCase();
                  final typeMatch =
                      _selectedType == 'All' ||
                      type.toLowerCase() == _selectedType.toLowerCase();
                  final statusMatch =
                      _statusFilter == 'All' ||
                      status.toLowerCase() == _statusFilter.toLowerCase();

                  return severityMatch && typeMatch && statusMatch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No pending threats.",
                      style: TextStyle(color: Colors.white24, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) =>
                      _buildIncidentCard(filteredDocs[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: electricTeal,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Add Incident",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddIncidentPage()));
        },
      ),
    );
  }

  Widget _buildIncidentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final userId =
        (data['userId'] ?? data['targetUserId'] ?? 'Anonymous Identity')
            .toString();
    final reason = (data['reason'] ?? 'Flagged by community filter').toString();
    final type = (data['type'] ?? 'General Violation').toString();
    final severity = (data['severity'] ?? 'medium').toString();
    final status = (data['status'] ?? 'pending').toString();
    final ts = data['timestamp'];
    DateTime? date;
    if (ts is Timestamp) date = ts.toDate();

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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      date != null ? timeago.format(date) : "PENDING REVIEW",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTypeBadge(type),
              const SizedBox(width: 8),
              _buildSeverityBadge(severity),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            reason,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
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
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  label: "RESOLVE",
                  color: electricTeal.withValues(alpha: 0.6),
                  textColor: Colors.black,
                  onTap: () => _processAction("resolve", doc.id, userId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentYellow.withValues(alpha: 0.2)),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(
          color: accentYellow,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color badgeColor;
    switch (severity.toLowerCase()) {
      case 'low':
        badgeColor = Colors.greenAccent;
        break;
      case 'high':
        badgeColor = errorRed;
        break;
      default:
        badgeColor = accentYellow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'resolved':
        badgeColor = Colors.greenAccent;
        break;
      case 'pending':
        badgeColor = accentYellow;
        break;
      default:
        badgeColor = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Future<void> _processAction(
    String action,
    String moderationId,
    String userId,
  ) async {
    try {
      if (action == "dismiss") {
        await SecurityQueueService.dismissIncident(moderationId, userId);
      } else if (action == "ban") {
        await SecurityQueueService.banUserAndRemove(
          moderationId: moderationId,
          userId: userId,
        );
      } else if (action == "resolve") {
        await SecurityQueueService.resolveIncident(moderationId, userId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("SECURITY ACTION EXECUTED: ${action.toUpperCase()}"),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to execute action: $action"),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
