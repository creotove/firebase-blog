import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';

class ChatPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String userId;

  const ChatPage({Key? key, required this.authBloc, required this.userId})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _messageController;
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messagesStream = FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String,
                          dynamic>?; // Cast message to Map<String, dynamic> or nullable

                      if (message != null) {
                        final isMe = message['sender'] == widget.userId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              message['text'] ?? '', // Add a null check here
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox(); // Return an empty SizedBox if message is null
                      }
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': messageText,
        'sender': widget.userId,
        'timestamp': Timestamp.now(),
      });
      _messageController.clear();
    }
  }
}
