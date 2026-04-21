import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Core
import 'core/firebase_options.dart';
import 'core/user_settings.dart';
import 'core/theme.dart';

// Splash & Home
import 'splash/splash_screen.dart';
import 'home/home_page.dart';
import 'connections/connections_page.dart';

// Features: Auth
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/reset_password_page.dart';

// Features: Profile
import 'features/profile/profile_page.dart';
import 'features/profile/account_profile_page.dart';

// Features: Settings
import 'features/settings/settings_page.dart';
import 'features/settings/accessibility_page.dart';
import 'features/settings/notifications_preferences_page.dart';
import 'features/settings/quiet_hours_page.dart';
import 'features/settings/app_behavior_page.dart';
import 'features/settings/auth_security_page.dart';
import 'features/settings/privacy_data_page.dart';
import 'features/settings/data_saver_page.dart';
import 'features/settings/session_management_page.dart';
import 'features/settings/developer_options_page.dart';
import 'features/settings/sync_reset_page.dart';

// Features: Community
import 'features/community/community_page.dart';
import 'features/community/feedback_page.dart';
import 'features/community/support_page.dart';
import 'features/community/about_page.dart';

// Features: Announcements & Testimonies
import 'features/announcements/announcements_page.dart';
import 'features/testimonies/testimonies_page.dart';

// Features: Devotionals & Lessons
import 'features/devotionals/devotionals_page.dart';
import 'features/devotionals/favorites_page.dart';
import 'features/lessons/lessons_page.dart';
import 'features/bible/bible_page.dart';
import 'features/prayer/prayer_page.dart';

// Features: Gamification & Learning
import 'features/gamification/gamification_page.dart';
import 'features/learning/learning_page.dart';
import 'features/resourcehub/resource_hub_page.dart';

// Features: Messages
import 'features/messages/messages_page.dart';
import 'features/messages/compose_message_page.dart';
import 'features/messages/notifications_page.dart';

// Features: Events
import 'features/events/events_page.dart';
import 'features/events/matchmaking_page.dart';

// Features: Media
import 'features/media/media_uploads_page.dart';

// Features: Admin
import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/manage_users_page.dart';
import 'features/admin/manage_content_page.dart';
import 'features/admin/moderation_page.dart';
import 'features/admin/analytics_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final settings = await UserSettings.loadLocal();
  runApp(SdaYouthApp(initialDarkMode: settings.darkModeEnabled));
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

  void _toggleDarkMode(bool enabled) {
    setState(() => _darkModeEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDA Youth App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/reset_password': (context) => const ResetPasswordPage(),
        '/connections': (context) => const ConnectionsPage(),
        '/settings': (context) => SettingsPage(onToggleDarkMode: _toggleDarkMode),

        // Settings sub-pages
        '/accessibility': (context) => const AccessibilityPage(),
        '/notifications_preferences': (context) => const NotificationsPreferencesPage(),
        '/quiet_hours': (context) => const QuietHoursPage(),
        '/app_behavior': (context) => const AppBehaviorPage(),
        '/auth_security': (context) => const AuthSecurityPage(),
        '/account_profile': (context) => const AccountProfilePage(),
        '/privacy_data': (context) => const PrivacyDataPage(),
        '/data_saver': (context) => const DataSaverPage(),
        '/session_management': (context) => const SessionManagementPage(),
        '/developer_options': (context) => const DeveloperOptionsPage(),
        '/sync_reset': (context) => const SyncResetPage(),

        // Community
        '/feedback': (context) => const FeedbackPage(),
        '/community': (context) => const CommunityPage(),
        '/support': (context) => const SupportPage(),
        '/about': (context) => const AboutPage(),
        '/announcements': (context) => const AnnouncementsPage(),
        '/testimonies': (context) => const TestimoniesPage(),

        // Devotionals & Lessons
        '/devotionals': (context) => const DevotionalsPage(),
        '/favorites': (context) => const FavoritesPage(),
        '/lessons': (context) => const LessonsPage(),
        '/bible': (context) => const BiblePage(),
        '/prayer': (context) => const PrayerPage(),

        // Gamification & Learning
        '/gamification': (context) => const GamificationPage(),
        '/learning': (context) => const LearningPage(),
        '/resource_hub': (context) => const ResourceHubPage(),

        // Messages
        '/messages': (context) => const MessagesPage(),
        '/compose_message': (context) => const ComposeMessagePage(),
        '/notifications': (context) => const NotificationsPage(),

        // Events
        '/events': (context) => const EventsPage(),
        '/matchmaking': (context) => const MatchmakingPage(),

        // Media
        '/media': (context) => const MediaUploadsPage(),

        // Admin
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/manage_users': (context) => const ManageUsersPage(),
        '/manage_content': (context) => const ManageContentPage(),
        '/moderation': (context) => const ModerationPage(),
        '/analytics': (context) => const AnalyticsPage(),
      },
    );
  }
}
