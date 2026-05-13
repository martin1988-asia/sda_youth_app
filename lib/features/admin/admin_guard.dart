// lib/features/admin/admin_guard.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:sda_youth_app/services/role_service.dart';
import 'package:sda_youth_app/core/user_role.dart';

/// AdminGuard — Premium RBAC enforcement for the SDA Youth Mission Control.
/// Ensures only authorized leaders can access sensitive administrative sectors.
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: RoleService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF050505),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF008080))),
          );
        }

        // Check if user is officially an Admin
        if (snapshot.data == UserRole.admin) {
          return child;
        }

        // Access Denied if roles do not match
        return const AdminAccessDenied();
      },
    );
  }
}

/// World-Class Restricted Access Interface.
class AdminAccessDenied extends StatelessWidget {
  const AdminAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.log('SECURITY ALERT: Unauthorized Admin Entry Attempt');
    }

    const Color accentYellow = Color(0xFFFFCC00); 
    const Color electricTeal = Color(0xFF00FFCC);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. Cinematic Security Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1a0a0a), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gpp_maybe_outlined,
                          size: 64,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "PROTOCOL ALPHA",
                        style: TextStyle(
                          color: accentYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "ACCESS RESTRICTED",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "This sector is reserved for Mission Administrators. Unauthorized attempts are logged for safety.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          label: const Text(
                            "RETURN TO HOME",
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: electricTeal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
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
}
