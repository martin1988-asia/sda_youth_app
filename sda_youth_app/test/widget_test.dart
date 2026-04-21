import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sda_youth_app/main.dart';
import 'package:sda_youth_app/features/settings/settings_page.dart';

void main() {
  testWidgets('App loads and shows splash screen', (WidgetTester tester) async {
    // Pump the root widget with required initialDarkMode argument
    await tester.pumpWidget(const SdaYouthApp(initialDarkMode: false));

    // Verify that the splash screen is displayed
    expect(find.text('SDA Youth App'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SettingsPage loads correctly', (WidgetTester tester) async {
    // Pump SettingsPage inside a MaterialApp for proper context
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(onToggleDarkMode: null), // ✅ provide argument
      ),
    );

    // Verify that SettingsPage renders
    expect(find.byType(SettingsPage), findsOneWidget);

    // Optional: check for the Settings title
    expect(find.text('Settings'), findsOneWidget);
  });
}
