import 'package:flutter/material.dart';
import 'chat_page.dart';

class StartChatPage extends StatelessWidget {
  const StartChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 Demo users
    final demoUsers = [
      {"id": "ngo3", "name": "NGO Care Givers", "email": "care@ngo.org"},
      {"id": "rest2", "name": "Restaurant SpiceHub", "email": "spice@rest.com"},
      {"id": "ngo4", "name": "NGO Food Shelter", "email": "shelter@ngo.org"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Start New Chat"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: demoUsers.length,
        itemBuilder: (context, index) {
          final user = demoUsers[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(user["name"]!),
            subtitle: Text(user["email"]!),
            trailing: const Icon(Icons.message, color: Colors.green),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    chatId: user["id"]!,
                    partnerName: user["name"]!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
