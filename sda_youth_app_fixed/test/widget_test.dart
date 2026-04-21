import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sda_youth_app/main.dart';
import 'package:sda_youth_app/splash/splash_screen.dart';
import 'package:sda_youth_app/features/auth/login_page.dart';
import 'package:sda_youth_app/features/auth/signup_page.dart';
import 'package:sda_youth_app/features/auth/forgot_password_page.dart';
import 'package:sda_youth_app/features/profile/profile_page.dart';
import 'package:sda_youth_app/features/settings/settings_page.dart';
import 'package:sda_youth_app/features/community/community_page.dart';
import 'package:sda_youth_app/features/messages/messages_page.dart';
import 'package:sda_youth_app/features/events/events_page.dart';
import 'package:sda_youth_app/features/admin/admin_dashboard_page.dart';
import 'package:sda_youth_app/core/user_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------
  // Splash & Startup
  // -------------------------
  group('App startup & splash screen', () {
    testWidgets('Splash screen renders correctly', (tester) async {
      await tester.pumpWidget(const SdaYouthApp(initialDarkMode: false));
      expect(find.text('SDA Youth App'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // -------------------------
  // Login Flow
  // -------------------------
  group('LoginPage', () {
    testWidgets('LoginPage renders form fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
    });

    testWidgets('Signup and Forgot Password links exist', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      expect(find.text("Don’t have an account? Sign up"), findsOneWidget);
      expect(find.text("Forgot Password?"), findsOneWidget);
    });

    testWidgets('LoginPage → SignupPage navigation', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const LoginPage(),
        routes: {'/signup': (context) => const SignupPage()},
      ));
      await tester.tap(find.text("Don’t have an account? Sign up"));
      await tester.pumpAndSettle();
      expect(find.byType(SignupPage), findsOneWidget);
    });

    testWidgets('LoginPage → ForgotPasswordPage navigation', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const LoginPage(),
        routes: {'/forgot_password': (context) => const ForgotPasswordPage()},
      ));
      await tester.tap(find.text("Forgot Password?"));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });
  });

  // -------------------------
  // Settings
  // -------------------------
  group('SettingsPage', () {
    testWidgets('SettingsPage renders with title and toggles', (tester) async {
      await tester.pumpWidget(MaterialApp(home: SettingsPage(onToggleDarkMode: (_) {})));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Data Saving Mode'), findsOneWidget);
    });
  });

  // -------------------------
  // Profile Validation
  // -------------------------
  group('ProfilePage validation', () {
    testWidgets('Empty Full Name shows error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Full Name'), findsOneWidget);
    });

    testWidgets('Empty Church shows error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Church'), findsOneWidget);
    });

    testWidgets('Valid input passes validation', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Church'), 'Central SDA');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pump();
      expect(find.textContaining('Full Name'), findsNothing);
      expect(find.textContaining('Church'), findsNothing);
    });
  });

  // -------------------------
  // Other Pages
  // -------------------------
  group('CommunityPage', () {
    testWidgets('CommunityPage renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityPage()));
      expect(find.byType(CommunityPage), findsOneWidget);
    });
  });

  group('MessagesPage', () {
    testWidgets('MessagesPage renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MessagesPage()));
      expect(find.byType(MessagesPage), findsOneWidget);
    });
  });

  group('EventsPage', () {
    testWidgets('EventsPage renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EventsPage()));
      expect(find.byType(EventsPage), findsOneWidget);
    });
  });

  group('AdminDashboardPage', () {
    testWidgets('AdminDashboardPage renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminDashboardPage()));
      expect(find.byType(AdminDashboardPage), findsOneWidget);
    });
  });

  // -------------------------
  // UserSettings Model
  // -------------------------
  group('UserSettings model', () {
    test('copyWith updates fields', () {
      final settings = UserSettings.defaults();
      final updated = settings.copyWith(darkModeEnabled: true);
      expect(updated.darkModeEnabled, true);
    });

    test('toJson and fromJson roundtrip', () {
      final settings = UserSettings.defaults();
      final json = settings.toJson();
      final from = UserSettings.fromJson(json);
      expect(from.darkModeEnabled, settings.darkModeEnabled);
    });

    test('resetToDefaults resets fields', () async {
      final settings = UserSettings(notificationsEnabled: false, darkModeEnabled: true);
      await settings.resetToDefaults();
      expect(settings.notificationsEnabled, true);
      expect(settings.darkModeEnabled, false);
    });
  });
}
