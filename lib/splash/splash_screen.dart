// lib/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import '../core/user_settings.dart';

/// Splash Sector — High-fidelity Initialization Terminal.
/// Manages cinematic branding and pre-fetches verified identities for a 0ms-lag transition.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAppSequencer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _startAppSequencer() async {
    // 1. Mission Start Tracking
    await FirebaseAnalytics.instance.logEvent(name: "app_launch_splash");

    // 2. Pre-fetch System Assets & Settings
    final startTime = DateTime.now();
    await UserSettings.loadLocal(); // Pre-warm settings cache

    // 3. Identity Verification Engine
    final user = FirebaseAuth.instance.currentUser;
    String targetRoute = '/login';

    if (user != null) {
      try {
        // Fetch real-time identity from Firestore ledger
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final status = userDoc.data()?['status'] ?? 'active';
          if (status == 'banned') {
            targetRoute = '/blocked';
          } else {
            targetRoute = '/home';
          }
        } else {
          // Auth exists but Firestore doc doesn't? Force profile setup.
          targetRoute = '/profile';
        }
      } catch (e) {
        // Fallback for connectivity issues during splash
        targetRoute = '/home';
      }
    }

    // 4. Ensure minimum branding exposure (1.5s total)
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    const minWait = 2000;
    if (elapsed < minWait) {
      await Future.delayed(Duration(milliseconds: minWait - elapsed));
    }

    if (!mounted) return;
    context.go(targetRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Cinematic Radial Glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF008080).withValues(alpha: 0.12),
                  const Color(0xFF050505),
                ],
              ),
            ),
          ),
          
          // Animated Branding Group
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/sda_logo.png',
                      height: 140,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "SDA YOUTH",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6.0,
                    ),
                  ),
                  Text(
                    "EMPOWERING THE FAITHFUL",
                    style: TextStyle(
                      color: const Color(0xFF00FFCC).withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  const SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      color: Color(0xFF008080),
                      minHeight: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Technical Footer
          const Positioned(
            bottom: 50,
            child: Text(
              "v1.0.0 ALPHA • SECURE CHANNEL",
              style: TextStyle(
                color: Colors.white12,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
