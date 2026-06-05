import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/core/user_role.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const Color teal = Color(0xFF00FFCC);
  static const Color red = Color(0xFFFF3333);
  static const Color orange = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: RoleService.getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != UserRole.admin) {
          return const Scaffold(body: Center(child: Text("Access denied")));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF050505),
          appBar: AppBar(
            title: const Text("Admin Intelligence"),
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _alerts(),

              const SizedBox(height: 16),

              _offenderList(context),

              const SizedBox(height: 16),

              _controlTile(
                context,
                Icons.people,
                "Manage Users",
                "/manage_users",
              ),
              _controlTile(
                context,
                Icons.security,
                "Moderation",
                "/moderation",
              ),
              _controlTile(
                context,
                Icons.analytics,
                "Metrics",
                "/admin_overview",
              ),
              _controlTile(context, Icons.settings, "System", "/settings"),
            ],
          ),
        );
      },
    );
  }

  // 🚨 ALERT SYSTEM
  Widget _alerts() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final riskyUsers = snapshot.data!.docs.where((u) {
          final data = u.data();
          final warnings = data['warnings'] ?? 0;
          final status = data['status'] ?? 'active';
          return warnings >= 2 && status != 'banned';
        }).toList();

        if (riskyUsers.isEmpty) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: red.withValues(alpha: 0.12), // ✅ FIXED
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: red),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${riskyUsers.length} high-risk users detected",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔴 OFFENDER LIST
  Widget _offenderList(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final offenders = snapshot.data!.docs.where((u) {
          final data = u.data();
          final warnings = data['warnings'] ?? 0;
          return warnings >= 2;
        }).toList();

        if (offenders.isEmpty) return const SizedBox();

        offenders.sort(
          (a, b) =>
              (b.data()['warnings'] ?? 0).compareTo(a.data()['warnings'] ?? 0),
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "OFFENDER WATCHLIST",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 10),

              ...offenders.take(5).map((u) {
                final data = u.data();
                final name = data['name'] ?? "User";
                final warnings = data['warnings'] ?? 0;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.white30),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    "⚠️ $warnings",
                    style: const TextStyle(color: Colors.orange),
                  ),
                  onTap: () => context.push('/manage_users'),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ✅ CONTROL TILE
  Widget _controlTile(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'admin_nav',
              parameters: {'page': route},
            );

            if (!kIsWeb) {
              FirebaseCrashlytics.instance.log('Nav: $route');
            }

            context.push(route);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, color: teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
