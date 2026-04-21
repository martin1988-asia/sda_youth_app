import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Widget _buildAdminTile(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 70, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          Column(
            children: [
              AppBar(
                title: const Text("Admin Dashboard"),
                centerTitle: true,
                elevation: 2,
                backgroundColor: Colors.teal,
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildAdminTile(context, "Manage Users", Icons.people, "/manage_users", Colors.blue),
                    _buildAdminTile(context, "Manage Content", Icons.library_books, "/manage_content", Colors.green),
                    _buildAdminTile(context, "Moderation Queue", Icons.report, "/moderation", Colors.orange),
                    _buildAdminTile(context, "Analytics", Icons.bar_chart, "/analytics", Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
