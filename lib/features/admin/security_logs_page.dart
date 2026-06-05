// lib/features/admin/security_logs_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sda_youth_app/services/security_queue_service.dart';
import 'package:sda_youth_app/features/admin/add_incident_page.dart';

class SecurityLogsPage extends StatefulWidget {
  const SecurityLogsPage({super.key});

  @override
  State<SecurityLogsPage> createState() => _SecurityLogsPageState();
}

class _SecurityLogsPageState extends State<SecurityLogsPage> {
  String _searchQuery = '';
  String _dateFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "SECURITY LOGS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by User ID or Action...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          // Date range filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("All"),
                  selected: _dateFilter == 'All',
                  onSelected: (_) => setState(() => _dateFilter = 'All'),
                  selectedColor: const Color(0xFF00FFCC),
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Last 7 days"),
                  selected: _dateFilter == '7',
                  onSelected: (_) => setState(() => _dateFilter = '7'),
                  selectedColor: Colors.greenAccent,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Last 30 days"),
                  selected: _dateFilter == '30',
                  onSelected: (_) => setState(() => _dateFilter = '30'),
                  selectedColor: Colors.yellowAccent,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('securityLogs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FFCC)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final now = DateTime.now();

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final action = (data['action'] ?? '')
                      .toString()
                      .toLowerCase();
                  final userId = (data['userId'] ?? '')
                      .toString()
                      .toLowerCase();
                  final ts = data['timestamp'];
                  DateTime? date;
                  if (ts is Timestamp) date = ts.toDate();

                  bool matchesSearch =
                      _searchQuery.isEmpty ||
                      action.contains(_searchQuery) ||
                      userId.contains(_searchQuery);

                  bool matchesDate = true;
                  if (_dateFilter == '7' && date != null) {
                    matchesDate = date.isAfter(
                      now.subtract(const Duration(days: 7)),
                    );
                  } else if (_dateFilter == '30' && date != null) {
                    matchesDate = date.isAfter(
                      now.subtract(const Duration(days: 30)),
                    );
                  }

                  return matchesSearch && matchesDate;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No audit logs found.",
                      style: TextStyle(color: Colors.white24),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();
                    final action = (data['action'] ?? 'unknown').toString();
                    final userId = (data['userId'] ?? 'Anonymous').toString();
                    final ts = data['timestamp'];
                    DateTime? date;
                    if (ts is Timestamp) date = ts.toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ACTION: ${action.toUpperCase()}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Target: $userId",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  date != null
                                      ? timeago.format(date)
                                      : "Unknown time",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            onSelected: (choice) async {
                              // Capture messenger before async
                              final messenger = ScaffoldMessenger.of(context);
                              bool success = false;
                              try {
                                if (choice == 'Re-open Incident') {
                                  await SecurityQueueService.enqueueIncident(
                                    userId: userId,
                                    reason: "Re-opened from logs",
                                    type: "General Violation",
                                    severity: "medium",
                                  );
                                  success = true;
                                } else if (choice == 'Ban User Again') {
                                  await SecurityQueueService.banUserAndRemove(
                                    moderationId:
                                        "log-${filteredDocs[index].id}",
                                    userId: userId,
                                  );
                                  success = true;
                                }
                              } catch (_) {
                                success = false;
                              }

                              if (!mounted) return;

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "$choice executed for $userId"
                                        : "Failed to execute $choice",
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'Re-open Incident',
                                child: Text("Re-open Incident"),
                              ),
                              PopupMenuItem(
                                value: 'Ban User Again',
                                child: Text("Ban User Again"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00FFCC),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Add Incident",
          style: TextStyle(color: Colors.black),
        ),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddIncidentPage()));
        },
      ),
    );
  }
}
