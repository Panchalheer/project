import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // 👈 to access themeNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _darkMode = prefs.getBool('isDarkMode') ?? false; // ✅ keep same key as main.dart
    });
  }

  // Save settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('isDarkMode', _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const SizedBox(height: 10),

          // 🔔 Notifications Section
          const Text(
            "Notifications",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text("Enable Notifications"),
            subtitle: const Text("Get alerts for new messages and updates"),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSettings();
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          const Divider(height: 30),

          // 🎨 App Appearance Section
          const Text(
            "App Appearance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Switch between light and dark themes"),
            value: _darkMode,
            onChanged: (value) async {
              setState(() => _darkMode = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', value);

              // ✅ Apply instantly across app
              themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(height: 30),

          // 💬 Help & Support Section
          const Text(
            "Help & Support",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("FAQs"),
            subtitle: const Text("Find answers to common questions"),
            onTap: () {
              // Navigate to FAQ Page (optional)
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Contact Support"),
            subtitle: const Text("Reach us at zerowaste.help@gmail.com"),
            onTap: () {
              // open mail or support screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text("Send Feedback"),
            subtitle: const Text("Share your thoughts about ZeroWaste"),
            onTap: () {
              // feedback form or redirect
            },
          ),
          const Divider(height: 30),

          // ℹ App version info
          const Center(
            child: Text(
              "ZeroWaste v1.0.0",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}