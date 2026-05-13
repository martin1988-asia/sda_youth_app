// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Core ---
import 'core/firebase_options.dart';
import 'core/role_guard.dart';
import 'core/theme.dart';
import 'core/user_role.dart';
import 'core/user_settings.dart';
import 'notifications_helper.dart';

// --- Feature Hubs ---
import 'home/home_page.dart';
import 'home/search_page.dart';
import 'home/create_post.dart';
import 'splash/splash_screen.dart';
import 'connections/connections_page.dart';

import 'features/auth/forgot_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/reset_password_page.dart';
import 'features/auth/signup_page.dart';

import 'features/profile/account_profile_page.dart';
import 'features/profile/profile_page.dart';

import 'features/settings/settings_page.dart';
import 'features/settings/accessibility_page.dart';
import 'features/settings/app_behavior_page.dart';
import 'features/settings/auth_security_page.dart';
import 'features/settings/data_saver_page.dart';
import 'features/settings/developer_options_page.dart';
import 'features/settings/notifications_preferences_page.dart';
import 'features/settings/privacy_data_page.dart';
import 'features/settings/quiet_hours_page.dart';
import 'features/settings/session_management_page.dart';
import 'features/settings/sync_reset_page.dart';

import 'features/community/community_page.dart';
import 'features/community/about_page.dart';
import 'features/community/feedback_page.dart';
import 'features/community/support_page.dart';
import 'features/announcements/announcements_page.dart';
import 'features/testimonies/testimonies_page.dart';
import 'features/media/media_uploads_page.dart';
import 'features/media/media_library_page.dart';
import 'features/posts/my_posts_page.dart';
import 'features/friends/friends_page.dart';

import 'features/bible/bible_page.dart';
import 'features/devotionals/devotionals_page.dart';
import 'features/devotionals/favorites_page.dart';
import 'features/lessons/lessons_page.dart';
import 'features/lessons/lesson_detail_page.dart';
import 'features/prayer/prayer_page.dart';
import 'features/gamification/gamification_page.dart';
import 'features/learning/learning_page.dart';
import 'features/resourcehub/resource_hub_page.dart';

import 'features/messages/chat_thread_page.dart';
import 'features/messages/messages_page.dart';
import 'features/messages/compose_message_page.dart';
import 'features/chat/global_chat_page.dart';
import 'features/messages/notifications_page.dart' as settings_notifications;

import 'features/events/events_page.dart';
import 'features/matchmaking/matchmaking_page.dart';

import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/admin_overview_page.dart';
import 'features/admin/analytics_page.dart';
import 'features/admin/manage_content_page.dart';
import 'features/admin/manage_users_page.dart';
import 'features/admin/moderation_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

class SdaYouthApp extends StatefulWidget {
  final bool initialDarkMode;
  const SdaYouthApp({super.key, required this.initialDarkMode});

  @override
  State<SdaYouthApp> createState() => _SdaYouthAppState();
}

class _SdaYouthAppState extends State<SdaYouthApp> {
  late bool _darkModeEnabled;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = widget.initialDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
      observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
      redirect: (context, state) async {
        final loc = state.matchedLocation;
        final user = auth.currentUser;
        final isAuthPath = loc == '/login' || loc == '/signup' || loc == '/forgot_password' || loc == '/reset_password';
        
        if (user == null) return (loc == '/splash' || isAuthPath) ? null : '/login';
        if (isAuthPath) return '/home';

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(path: '/blocked', builder: (context, state) => const BlockedPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
        GoRoute(path: '/forgot_password', builder: (context, state) => const ForgotPasswordPage()),
        GoRoute(path: '/reset_password', builder: (context, state) => const ResetPasswordPage()),
        
        GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
        GoRoute(path: '/notifications', builder: (context, state) => const NotificationsInboxPage()),
        GoRoute(path: '/create_post', builder: (context, state) => const CreatePostPage()),
        GoRoute(path: '/community', builder: (context, state) => const CommunityPage()),
        GoRoute(path: '/friends', builder: (context, state) => const FriendsPage()),
        GoRoute(path: '/connections', builder: (context, state) => const ConnectionsPage()),
        GoRoute(path: '/my_posts', builder: (context, state) => const MyPostsPage()),
        GoRoute(path: '/testimonies', builder: (context, state) => const TestimoniesPage()),
        GoRoute(path: '/media', builder: (context, state) => const MediaUploadsPage()),
        GoRoute(path: '/media_library', builder: (context, state) => const MediaLibraryPage()),
        GoRoute(path: '/events', builder: (context, state) => const EventsPage()),
        GoRoute(path: '/matchmaking', builder: (context, state) => const MatchmakingPage()),
        GoRoute(path: '/bible', builder: (context, state) => const BiblePage()),
        GoRoute(path: '/prayer', builder: (context, state) => const PrayerPage()),
        GoRoute(path: '/devotionals', builder: (context, state) => const DevotionalsPage()),
        GoRoute(path: '/favorites', builder: (context, state) => const FavoritesPage()),
        GoRoute(path: '/lessons', builder: (context, state) => const LessonsPage()),
        GoRoute(path: '/lessons/:id', builder: (context, state) => LessonDetailPage(lessonId: state.pathParameters['id']!)),
        GoRoute(path: '/learning', builder: (context, state) => const LearningPage()),
        GoRoute(path: '/gamification', builder: (context, state) => const GamificationPage()),
        GoRoute(path: '/resource_hub', builder: (context, state) => const ResourceHubPage()),
        GoRoute(path: '/announcements', builder: (context, state) => const AnnouncementsPage()),
        GoRoute(path: '/messages', builder: (context, state) => const MessagesPage()),
        GoRoute(path: '/messages/:id', builder: (context, state) => ChatThreadPage(recipientId: state.pathParameters['id']!)),
        GoRoute(path: '/compose_message', builder: (context, state) => const ComposeMessagePage()),
        GoRoute(path: '/global_chat', builder: (context, state) => const GlobalChatPage()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(path: '/account_profile', builder: (context, state) => const AccountProfilePage()),
        GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
        GoRoute(path: '/support', builder: (context, state) => const SupportPage()),
        GoRoute(path: '/feedback', builder: (context, state) => const FeedbackPage()),
        GoRoute(path: '/settings', builder: (context, state) => SettingsPage(onToggleDarkMode: (v) => setState(() => _darkModeEnabled = v))),
        GoRoute(path: '/accessibility', builder: (context, state) => const AccessibilityPage()),
        GoRoute(path: '/app_behavior', builder: (context, state) => const AppBehaviorPage()),
        GoRoute(path: '/auth_security', builder: (context, state) => const AuthSecurityPage()),
        GoRoute(path: '/data_saver', builder: (context, state) => const DataSaverPage()),
        GoRoute(path: '/developer_options', builder: (context, state) => const DeveloperOptionsPage()),
        GoRoute(path: '/notification_settings', builder: (context, state) => const settings_notifications.NotificationsPage()),
        GoRoute(path: '/notifications_preferences', builder: (context, state) => const NotificationsPreferencesPage()),
        GoRoute(path: '/privacy_data', builder: (context, state) => const PrivacyDataPage()),
        GoRoute(path: '/quiet_hours', builder: (context, state) => const QuietHoursPage()),
        GoRoute(path: '/session_management', builder: (context, state) => const SessionManagementPage()),
        GoRoute(path: '/sync_reset', builder: (context, state) => const SyncResetPage()),

        // Admin Routes
        GoRoute(path: '/admin_dashboard', builder: (context, state) => const AdminDashboardPage(), redirect: (ctx, st) => RoleGuard.allowOnly(UserRole.admin)),
        GoRoute(path: '/admin_overview', builder: (context, state) => const AdminOverviewPage(), redirect: (ctx, st) => RoleGuard.allowOnly(UserRole.admin)),
        GoRoute(path: '/manage_users', builder: (context, state) => const ManageUsersPage(), redirect: (ctx, st) => RoleGuard.allowOnly(UserRole.admin)),
        GoRoute(path: '/manage_content', builder: (context, state) => const ManageContentPage(), redirect: (ctx, st) => RoleGuard.allowOnly(UserRole.admin)),
        GoRoute(path: '/moderation', builder: (context, state) => const ModerationPage(), redirect: (ctx, st) => RoleGuard.allowOnly(UserRole.admin)),
        GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsPage(), redirect: (ctx, st) => RoleGuard.allowOnly(UserRole.admin)),
      ],
    );

    return MaterialApp.router(
      title: 'SDA Youth App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}

class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text("Access Restricted", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Contact support to appeal this action.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("Exit")),
          ],
        ),
      ),
    );
  }
}

class NotificationsInboxPage extends StatelessWidget {
  const NotificationsInboxPage({super.key});

  static const Color electricTeal = Color(0xFF00FFCC);
  static const Color premiumBlack = Color(0xFF050505);
  static const Color accentYellow = Color(0xFFFFCC00);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(backgroundColor: premiumBlack, body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: premiumBlack,
      body: Stack(
        children: [
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
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(child: _buildNotificationStream(uid)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text("ALERTS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const Spacer(),
          const Icon(Icons.notifications_active_outlined, color: electricTeal, size: 22),
        ],
      ),
    );
  }

  Widget _buildNotificationStream(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: electricTeal));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final bool isRead = data['read'] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isRead ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isRead ? Colors.white10 : electricTeal.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: _buildNotificationAvatar(data),
                title: Text(
                  data['title'] ?? 'COMMUNITY ALERT',
                  style: TextStyle(color: isRead ? Colors.white70 : Colors.white, fontWeight: isRead ? FontWeight.w500 : FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(data['body'] ?? '', style: TextStyle(color: isRead ? Colors.white38 : Colors.white60, fontSize: 13)),
                ),
                onTap: () {
                  docs[index].reference.update({'read': true});
                  final route = data['data']?['route'];
                  if (route != null) context.push(route);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationAvatar(Map<String, dynamic> data) {
    final fromUserId = data['fromUserId'] as String?;
    final type = data['type'] ?? 'general';
    IconData icon; Color iconColor;

    switch (type) {
      case 'friend_request': icon = Icons.person_add_alt_1; iconColor = electricTeal; break;
      case 'reaction': icon = Icons.favorite_rounded; iconColor = Colors.redAccent; break;
      case 'comment': icon = Icons.chat_bubble_rounded; iconColor = Colors.blueAccent; break;
      default: icon = Icons.notifications_active_rounded; iconColor = accentYellow;
    }

    // Defensive check: only use FutureBuilder if fromUserId is NOT null AND NOT empty
    if (fromUserId == null || fromUserId.isEmpty) return _avatarWrapper(null, icon, iconColor);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(fromUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final photo = userData?['photoURL'] as String?;
        return _avatarWrapper(photo, icon, iconColor);
      },
    );
  }

  Widget _avatarWrapper(String? photo, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5))),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.black,
        // CRITICAL FIX: Only use NetworkImage if photo is NOT null AND NOT empty
        backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
        child: (photo == null || photo.isEmpty) ? Icon(icon, color: color, size: 20) : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          const Text("LEDGER IS CLEAR", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }
}
