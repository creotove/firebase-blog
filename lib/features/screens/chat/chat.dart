import 'dart:io';
import 'package:blog/features/models/message.dart';
import 'package:blog/features/screens/chat/chat_service.dart';
import 'package:blog/features/screens/chat/message_sender_helper.dart';
import 'package:blog/features/screens/chat/argument_helper.dart.dart';
import 'package:blog/theme/app_pallete.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:blog/widgets/audio_player.dart';
import 'package:blog/widgets/chat_send_file.dart';
import 'package:blog/widgets/text_filed.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String receiverUserId;
  final String? currentUserId;

  const ChatPage({
    super.key,
    required this.authBloc,
    required this.receiverUserId,
    this.currentUserId = '',
  });

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

        await MessageHelper().sendMessage(
          chatMessage,
          widget.currentUserId!,
          widget.receiverUserId,
          MessageType.text,
        );
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void _pickImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      final arguments = SendImageArguments(
        image: pickedImage,
        currentUserId: widget.currentUserId!,
        receiverUserId: widget.receiverUserId,
      );
      await Navigator.pushNamed(
        context,
        '/send-image',
        arguments: arguments,
      );
    }
  }

  Future<File?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  void _pickAudio() async {
    final pickedAudio = await pickAudio();
    if (pickedAudio != null) {
      final arguments = SendAudioArguments(
        audio: pickedAudio,
        currentUserId: widget.currentUserId!,
        receiverUserId: widget.receiverUserId,
      );
      await Navigator.pushNamed(
        context,
        '/send-audio',
        arguments: arguments,
      );
    }
  }

  Future<File?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  void _pickDocument() async {
    final pickedDocument = await pickDocument();
    if (pickedDocument != null) {
      final arguments = SendDocumentArguments(
        document: pickedDocument,
        currentUserId: widget.currentUserId!,
        receiverUserId: widget.receiverUserId,
      );
      await Navigator.pushNamed(
        context,
        '/send-document',
        arguments: arguments,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
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
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16.0,
                              runSpacing: 16.0,
                              children: <Widget>[
                                ChatSendFile(
                                  icon: Icons.image_sharp,
                                  text: "Gallery",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    _pickImage();
                                  },
                                ),
                                ChatSendFile(
                                  icon: Icons.headphones,
                                  text: "Audio",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    _pickAudio();
                                  },
                                ),
                                ChatSendFile(
                                  icon: Icons.insert_drive_file,
                                  text: "Document",
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    _pickDocument();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> message = document.data() as Map<String, dynamic>;
    final isMe = message['senderId'] == widget.currentUserId;
    final decryptedMessage = message['isEncrypted']
        ? EncryptionHelper.decryptMessage(message['message'])
        : message['message'];

    final messageType = message['type'];

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
        child: _buildMessageContent(messageType, decryptedMessage, message),
      ),
    );
  }

  void navigateToShowSentImage(String imagePath) {
    Navigator.pushNamed(
      context,
      '/show-image',
      arguments: imagePath,
    );
  }

  Widget _buildMessageContent(
    String messageType,
    String decryptedMessage,
    Map<String, dynamic> message,
  ) {
    switch (messageType) {
      case "text":
        return Text(
          decryptedMessage,
          style: const TextStyle(color: Colors.white),
        );
      case "image":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => {navigateToShowSentImage(message['imageUrl'])},
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(message['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        );
      case "audio":
        return SizedBox(
            width: 200,
            child: CompactAudioPlayerWidget(audioUrl: message['audioUrl']));
      case "document":
        return GestureDetector(
          onTap: () async {
            try {
              print('Opening document');
            } catch (e) {
              print('Error opening file: $e');
            }
          },
          child: const SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.insert_drive_file, color: Colors.white),
                Text(
                  'Document',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );

      default:
        return const Text('File corrupted or not supported',
            style: TextStyle(color: Colors.white));
    }
  }
}
