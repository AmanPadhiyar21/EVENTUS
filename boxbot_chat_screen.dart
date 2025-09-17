import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BoxBotChatScreen extends StatefulWidget {
  const BoxBotChatScreen({super.key});

  @override
  State<BoxBotChatScreen> createState() => _BoxBotChatScreenState();
}

class _BoxBotChatScreenState extends State<BoxBotChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, {"sender": "user", "text": text});
    });
    _controller.clear();

    final reply = await ApiService.sendBoxBotMessage(text);

    setState(() {
      _messages.insert(0, {"sender": "bot", "text": reply});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ main background
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "ChatBot EVENTUS",
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 6,
        shadowColor: Colors.greenAccent.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.greenAccent), // ✅ back arrow color
      ),
      body: Column(
        children: [
          // 📜 Chat messages
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["sender"] == "user";
                  return Align(
                    alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.greenAccent[400]
                            : Colors.grey[850],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft:
                          isUser ? const Radius.circular(18) : Radius.zero,
                          bottomRight:
                          isUser ? Radius.zero : const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(2, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        msg["text"]!,
                        style: TextStyle(
                          color: isUser ? Colors.black : Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ✍️ Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.greenAccent.withOpacity(0.4)),
              ),
            ),
            child: Row(
              children: [
                // Input field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),

                // Send button
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.greenAccent,
                    child: const Icon(Icons.send,
                        color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
