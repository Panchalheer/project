import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String partnerName;

  const ChatPage({super.key, required this.chatId, required this.partnerName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  // 🚀 In-memory chat messages
  final Map<String, List<Map<String, dynamic>>> _chatStorage = {};

  List<Map<String, dynamic>> get _messages =>
      _chatStorage[widget.chatId] ?? [];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMsg = {
      "text": text,
      "isMe": true,
      "timestamp": DateTime.now(),
    };

    setState(() {
      _chatStorage.putIfAbsent(widget.chatId, () => []);
      _chatStorage[widget.chatId]!.add(newMsg);
    });

    _controller.clear();

    // 🚀 Fake partner reply
    Future.delayed(const Duration(seconds: 1), () {
      final reply = {
        "text": "Auto-reply from ${widget.partnerName}",
        "isMe": false,
        "timestamp": DateTime.now(),
      };
      setState(() {
        _chatStorage[widget.chatId]!.add(reply);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg["isMe"] as bool;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg["text"]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
