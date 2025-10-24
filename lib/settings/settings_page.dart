import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show themeNotifier;

/// ✅ SETTINGS PAGE
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('isDarkMode') ?? false;
      themeNotifier.value = _darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 10),

          // Dark Mode
          Text("App Appearance",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Card(
            color: theme.cardColor,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: Colors.grey.withOpacity(0.3),
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Switch between light and dark themes"),
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                _saveSettings();
              },
              secondary: Icon(Icons.dark_mode, color: theme.iconTheme.color),
            ),
          ),

          const SizedBox(height: 20),

          // Help & Support
          Text("Help & Support",
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Card(
            color: theme.cardColor,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: Colors.grey.withOpacity(0.3),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help_outline, color: theme.iconTheme.color),
                  title: const Text("FAQs"),
                  subtitle: const Text("Find answers to common questions"),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FAQPage()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.support_agent, color: theme.iconTheme.color),
                  title: const Text("Contact Support"),
                  subtitle: const Text("Chat or email our support team"),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SupportPage()));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                  Icon(Icons.feedback_outlined, color: theme.iconTheme.color),
                  title: const Text("Send Feedback"),
                  subtitle: const Text("Share your thoughts about ZeroWaste"),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FeedbackPage()));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Center(
            child: Text("ZeroWaste v1.0.0",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

/// ❓ FAQ PAGE
class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final faqs = [
      {"q": "What is ZeroWaste?", "a": "ZeroWaste connects restaurants with NGOs to reduce food waste."},
      {"q": "How do I register?", "a": "You can register as a restaurant, NGO, or admin via the signup page."},
      {"q": "Can I track food deliveries?", "a": "Yes, delivery progress is shown once food is accepted by an NGO."},
      {"q": "Is my data secure?", "a": "Yes, all data is stored securely in Firebase."},
      {"q": "How do I change my profile?", "a": "You can edit your profile from the profile page after logging in."},
      {"q": "Can I delete my account?", "a": "Yes, contact support to request account deletion."},
      {"q": "How do I report an issue?", "a": "Use the Feedback page to report issues or send suggestions."},
      {"q": "Are notifications customizable?", "a": "Yes, you can enable or disable notifications in settings."},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("FAQs")),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            color: theme.cardColor,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: Colors.grey.withOpacity(0.3),
            child: ExpansionTile(
              leading: Icon(Icons.question_mark, color: theme.colorScheme.primary),
              title: Text(faq['q']!,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(faq['a']!, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 💬 FEEDBACK PAGE
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'message': _controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Send Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("We value your feedback!",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Enter your feedback here...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitFeedback,
              icon: const Icon(Icons.send),
              label: _isLoading ? const Text("Sending...") : const Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📞 SUPPORT PAGE
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Support")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.support_agent, size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text("Need Assistance?",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                "We’re here to help! You can reach out to our support team any time.",
                textAlign: TextAlign.center),
            const SizedBox(height: 25),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email, color: theme.iconTheme.color),
                    title: const Text("Email Support"),
                    subtitle: const Text("zerowaste.help@gmail.com"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.chat_bubble_outline, color: theme.iconTheme.color),
                    title: const Text("Live Chat"),
                    subtitle: const Text("Coming soon..."),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.language, color: theme.iconTheme.color),
                    title: const Text("Visit Website"),
                    subtitle: const Text("www.zerowasteapp.com"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
