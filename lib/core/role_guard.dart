// lib/core/role_guard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sda_youth_app/core/user_role.dart';
import 'package:sda_youth_app/services/role_service.dart';

/// RoleGuard — High-fidelity Security Gate for SDA Youth.
/// Wraps protected sectors with real-time identity permission checks.
class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: RoleService.getAuthorizedRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF050505),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC))),
          );
        }

        final role = snapshot.data ?? UserRole.user;
        if (allowedRoles.contains(role)) return child;

        // Visual Identity for restricted attempts
        return const _RestrictedSectorView();
      },
    );
  }

  /// High-performance redirect engine for GoRouter.
  /// Synchronizes identity context with routing authority.
  static Future<String?> allowOnly(UserRole requiredRole) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '/login';

    final role = await RoleService.getAuthorizedRole();
    if (role == requiredRole) return null;

    return '/home';
  }
}

/// Premium Restricted Access Interface
class _RestrictedSectorView extends StatelessWidget {
  const _RestrictedSectorView();

  @override
  Widget build(BuildContext context) {
    const Color accentYellow = Color(0xFFFFCC00); 
    const Color electricTeal = Color(0xFF00FFCC);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1a0a0a), Color(0xFF050505)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gpp_maybe_outlined, size: 64, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "PROTOCOL ALPHA",
                    style: TextStyle(color: accentYellow, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ACCESS RESTRICTED",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your identity does not have the required authority for this sector.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: electricTeal, size: 18),
                    label: const Text(
                      "RETURN TO BASE", 
                      style: TextStyle(color: electricTeal, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
