// ignore_for_file: use_rethrow_when_possible, avoid_print

import 'package:blog/features/screens/chat/chat_service.dart';
import 'package:blog/theme/app_pallete.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:blog/widgets/text_filed.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';

class ChatPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String receiverUserId;
  final String? currentUserId;

  const ChatPage(
      {super.key,
      required this.authBloc,
      required this.receiverUserId,
      this.currentUserId = ''});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService _chatService = ChatService();

  void sendMessage() async {
    try {
      if (_messageController.text.trim().isNotEmpty) {
        final chatMessage = _messageController.text.trim();
        _messageController.clear();
        await _chatService.sendMessage(
          chatMessage,
          widget.currentUserId!,
          widget.receiverUserId,
        );
      }
    } catch (e) {
      print(e);
      throw e;
    }
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
            child: _buildMessagesList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: BlogEditor(
                    controller: _messageController,
                    hintText: 'Type a message...',
                    labelText: 'Message',
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Create Message list
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(
          widget.currentUserId!, widget.receiverUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No messages'));
        } else {
          final messages = snapshot.data!.docs;
          return ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _buildMessageItem(messages[index]);
            },
          );
        }
      },
    );
  }

  // Create message item
  Widget _buildMessageItem(DocumentSnapshot docuemnt) {
    Map<String, dynamic> message = docuemnt.data() as Map<String, dynamic>;
    final isMe = message['senderId'] == widget.currentUserId;
    final decryptedMessage =
        EncryptionHelper.decryptMessage(message['message']);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(10),
          gradient: isMe
              ? const LinearGradient(
                  colors: [AppPallete.gradient1, AppPallete.gradient2],
                )
              : null,
        ),
        child: Text(
          decryptedMessage,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
