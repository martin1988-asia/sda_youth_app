import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return; // ✅ safe check
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return; // ✅ safe check
        _showSnack(context, "Could not open link");
      }
    } catch (e) {
      if (!context.mounted) return; // ✅ safe check
      _showSnack(context, "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Image.asset('assets/sda_logo.png', height: 70),
                    const SizedBox(height: 12),
                    AppBar(
                      title: const Text("Support & About"),
                      backgroundColor: Colors.teal,
                    ),
                    const SizedBox(height: 12),

                    const ListTile(
                      title: Text("Help Center / FAQs",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text("Frequently Asked Questions"),
                      onTap: () => _showSnack(context, "FAQs feature coming soon"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.book),
                      title: const Text("User Guide"),
                      onTap: () => _showSnack(context, "User guide coming soon"),
                    ),
                    const Divider(),

                    const ListTile(
                      title: Text("Contact Support",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: const Text("Email Support"),
                      subtitle: const Text("support@sda-youth-app.org"),
                      onTap: () => _launchUrl("mailto:support@sda-youth-app.org", context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text("Call Support"),
                      subtitle: const Text("+264-81-234-5678"),
                      onTap: () => _launchUrl("tel:+264812345678", context),
                    ),
                    const Divider(),

                    const ListTile(
                      title: Text("Feedback",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.feedback),
                      title: const Text("Send Feedback"),
                      onTap: () => Navigator.pushNamed(context, '/feedback'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text("Rate the App"),
                      onTap: () => _showSnack(context, "Rating feature coming soon"),
                    ),
                    const Divider(),

                    const ListTile(
                      title: Text("About",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text("Version"),
                      subtitle: const Text("1.0.0"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text("Developed By"),
                      subtitle: const Text("SDA Youth Community, Namibia"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text("Privacy Policy"),
                      onTap: () => _launchUrl("https://sda-youth-app.org/privacy", context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.gavel),
                      title: const Text("Terms of Service"),
                      onTap: () => _launchUrl("https://sda-youth-app.org/terms", context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
