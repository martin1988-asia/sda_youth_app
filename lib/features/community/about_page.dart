import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open link")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
                constraints: const BoxConstraints(maxWidth: 700),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Image.asset('assets/sda_logo.png', height: 70)),
                      const SizedBox(height: 12),
                      AppBar(
                        title: const Text("About SDA Youth App"),
                        backgroundColor: Colors.teal,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Mission",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Our mission is to empower Seventh-day Adventist youth with a platform that "
                        "fosters spiritual growth, community engagement, and meaningful connections. "
                        "We aim to provide tools that help young people live their faith daily, "
                        "share experiences, and build supportive relationships.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Vision",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Our vision is to create a unified, inclusive, and faith-centered digital community "
                        "where SDA youth can grow spiritually, connect across regions, and contribute "
                        "to the mission of the church in the modern world.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Core Values",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "• Faith: Keeping Christ at the center of all interactions.\n"
                        "• Community: Building strong, supportive relationships among youth.\n"
                        "• Inclusivity: Welcoming all backgrounds, languages, and cultures.\n"
                        "• Growth: Encouraging personal, spiritual, and professional development.\n"
                        "• Service: Inspiring youth to serve their churches and communities.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "About the App",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "The SDA Youth App is designed to be a safe, engaging, and interactive space "
                        "for young Adventists. It integrates features such as community posts, "
                        "daily devotionals, matchmaking for friendships and mentorship, and "
                        "personalized settings to ensure a meaningful experience.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Version",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("1.0.0", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      const Text(
                        "Developed By",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("SDA Youth Community, Namibia",
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      const Text(
                        "Legal & Policies",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
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
          ),
        ],
      ),
    );
  }
}
