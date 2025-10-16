import 'package:flutter/material.dart';
import 'side_menu.dart';
import 'top_bar.dart';
import '../admin_dashboard.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String _selectedPage = "Dashboard";

  Widget _getPage() {
    switch (_selectedPage) {
      case "Dashboard":
        return const AdminDashboardPage();
      case "Restaurant Verification":
        return const Center(child: Text("🍽️ Restaurant Verification Page"));
      case "NGO Verification":
        return const Center(child: Text("🤝 NGO Verification Page"));
      case "User Management":
        return const Center(child: Text("👥 User Management Page"));
      case "Content Moderation":
        return const Center(child: Text("🛡️ Content Moderation Page"));
      case "Settings":
        return const Center(child: Text("⚙️ Settings Page"));
      default:
        return const Center(child: Text("Unknown Page"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selected: _selectedPage,
            onMenuTap: (page) => setState(() => _selectedPage = page),
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(child: _getPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
