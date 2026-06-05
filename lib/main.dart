// ✅ FINAL PRODUCTION MAIN — FULLY CONSISTENT WITH CHAT SYSTEM

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/route_observer.dart';
import 'core/firebase_options.dart';
import 'core/theme.dart';
import 'core/user_role.dart';
import 'core/user_settings.dart';
import 'core/role_guard.dart';

import 'notifications_helper.dart';
import 'splash/splash_screen.dart';

import 'home/home_page.dart';
import 'home/search_page.dart';
import 'home/create_post.dart';

import 'widgets/post_card.dart';

import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/reset_password_page.dart';

import 'features/messages/messages_page.dart';
import 'features/messages/chat_thread_page.dart';
import 'features/messages/notifications_page.dart';

import 'features/profile/profile_page.dart';
import 'features/profile/profile_view_page.dart';

import 'features/settings/settings_page.dart';

import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/manage_users_page.dart';
import 'features/admin/moderation_page.dart';
import 'features/admin/analytics_page.dart';
import 'features/admin/manage_content_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  await NotificationsHelper.init();

  final settings = await UserSettings.loadLocal();

  runApp(SdaYouthApp(initialDarkMode: settings.darkModeEnabled));
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class SdaYouthApp extends StatefulWidget {
  final bool initialDarkMode;

  const SdaYouthApp({super.key, required this.initialDarkMode});

  @override
  State<SdaYouthApp> createState() => _SdaYouthAppState();
}

class _SdaYouthAppState extends State<SdaYouthApp> with WidgetsBindingObserver {
  late bool _darkModeEnabled;
  String? uid;

  @override
  void initState() {
    super.initState();

    _darkModeEnabled = widget.initialDarkMode;
    WidgetsBinding.instance.addObserver(this);

    uid = FirebaseAuth.instance.currentUser?.uid;
    _setOnline(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (uid == null) return;

    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else {
      _setOnline(false);
    }
  }

  Future<void> _setOnline(bool online) async {
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;

    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
      observers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        routeObserver,
      ],

      redirect: (context, state) {
        final user = auth.currentUser;
        final path = state.matchedLocation;

        final isAuthRoute =
            path == '/login' ||
            path == '/signup' ||
            path == '/forgot_password' ||
            path == '/reset_password';

        if (user == null) {
          if (path == '/splash' || isAuthRoute) return null;
          return '/login';
        }

        if (isAuthRoute) return '/home';

        return null;
      },

      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),

        GoRoute(path: '/home', builder: (_, _) => const HomePage()),

        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),

        GoRoute(
          path: '/post/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return Scaffold(
              backgroundColor: AppTheme.bg,
              appBar: AppBar(),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: PostCard(postId: id),
                ),
              ),
            );
          },
        ),

        GoRoute(
          path: '/profile_view/:uid',
          builder: (_, state) =>
              ProfileViewPage(userId: state.pathParameters['uid']!),
        ),

        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
        GoRoute(
          path: '/forgot_password',
          builder: (_, _) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset_password',
          builder: (_, _) => const ResetPasswordPage(),
        ),

        GoRoute(path: '/search', builder: (_, _) => const SearchPage()),

        GoRoute(
          path: '/create_post',
          builder: (_, _) => const CreatePostPage(),
        ),

        GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),

        // ✅ ✅ ✅ FINAL CHAT ROUTE (FIXED)
        GoRoute(
          path: '/chat',
          builder: (_, state) =>
              ChatThreadPage(otherUserId: state.extra as String),
        ),

        GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),

        GoRoute(
          path: '/settings',
          builder: (_, _) => SettingsPage(
            onToggleDarkMode: (value) {
              setState(() => _darkModeEnabled = value);
            },
          ),
        ),

        // ✅ ADMIN (UNCHANGED)
        GoRoute(
          path: '/admin_dashboard',
          builder: (_, _) => const AdminDashboardPage(),
          redirect: (_, _) => RoleGuard.allowOnly(UserRole.admin),
        ),
        GoRoute(
          path: '/manage_users',
          builder: (_, _) => const ManageUsersPage(),
          redirect: (_, _) => RoleGuard.allowOnly(UserRole.admin),
        ),
        GoRoute(
          path: '/moderation',
          builder: (_, _) => const ModerationPage(),
          redirect: (_, _) => RoleGuard.allowOnly(UserRole.admin),
        ),
        GoRoute(
          path: '/manage_content',
          builder: (_, _) => const ManageContentPage(),
          redirect: (_, _) => RoleGuard.allowOnly(UserRole.admin),
        ),
        GoRoute(
          path: '/analytics',
          builder: (_, _) => const AnalyticsPage(),
          redirect: (_, _) => RoleGuard.allowOnly(UserRole.admin),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SDA Youth App',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
