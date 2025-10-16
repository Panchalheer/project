import 'package:flutter/material.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // 🚀 Demo chat data
  final List<Map<String, String>> demoChats = [
    {"id": "ngo1", "name": "NGO Helping Hands", "lastMessage": "Thanks for the food!"},
    {"id": "rest1", "name": "Restaurant GreenLeaf", "lastMessage": "Pickup at 7 PM"},
    {"id": "ngo2", "name": "NGO Food For All", "lastMessage": "Can we request more meals?"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Chats"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: demoChats.length,
        itemBuilder: (context, index) {
          final chat = demoChats[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.chat, color: Colors.white),
            ),
            title: Text(chat["name"]!),
            subtitle: Text(chat["lastMessage"]!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    chatId: chat["id"]!,
                    partnerName: chat["name"]!,
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
