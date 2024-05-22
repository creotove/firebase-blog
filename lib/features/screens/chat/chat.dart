import 'package:blog/features/screens/chat/chat_service.dart';
import 'package:blog/features/screens/chat/argument_helper.dart.dart';
import 'package:blog/theme/app_pallete.dart';
import 'package:blog/utils/encryption_helper.dart';
import 'package:blog/widgets/audio_player.dart';
import 'package:blog/widgets/chat_send_file.dart';
import 'package:blog/widgets/text_filed.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blog/authentication.dart';

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
  final ValueNotifier<Set<String>> _selectedMessages =
      ValueNotifier<Set<String>>({});
  bool _selectionMode = false;

  void _onMessageLongPress(String messageId) {
    final currentSelection = _selectedMessages.value;
    if (currentSelection.contains(messageId)) {
      if (currentSelection.length == 1) {
        _selectionMode = false;
        _selectedMessages.value = {};
        return;
      }
      _selectedMessages.value = Set.from(currentSelection)..remove(messageId);
    } else {
      _selectedMessages.value = Set.from(currentSelection)..add(messageId);
      _selectionMode = true;
    }
  }

  Future<void> toggleLike(String messageId) async {
    final currentUserId = widget.currentUserId!;
    final List users = [widget.currentUserId, widget.receiverUserId];
    users.sort();
    final messageRef = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(users[0] + '_' + users[1])
        .collection('messages')
        .doc(messageId);
    final messageDoc = await messageRef.get();
    if (messageDoc.exists) {
      List<dynamic> likedBy = messageDoc['likedBy'] ?? [];
      if (likedBy.contains(currentUserId)) {
        likedBy.remove(currentUserId);
      } else {
        likedBy.add(currentUserId);
      }
      await messageRef.update({'likedBy': likedBy});
    }
  }

  bool isMessageLiked(Map<String, dynamic> message) {
    final currentUserId = widget.currentUserId!;
    List<dynamic> likedBy = message['likedBy'] ?? [];
    return likedBy.contains(currentUserId);
  }

  void _pickImage() async {
    final pickedImage = await _chatService.pickImage();
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

  void _pickAudio() async {
    final pickedAudio = await _chatService.pickAudio();
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

  void _pickDocument() async {
    final pickedDocument = await _chatService.pickDocument();
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
        title: const Text("Chat"),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: _selectedMessages,
            builder: (context, selectedMessages, child) {
              if (selectedMessages.isEmpty) {
                return Container();
              }
              print('Selected messages: $selectedMessages');
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      _selectionMode = false;
                      _selectedMessages.value = {};
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      final deleted = await _chatService.deleteSelectedMessages(
                          widget.currentUserId!,
                          widget.receiverUserId,
                          selectedMessages);
                      if (deleted) {
                        _selectionMode = false;
                        _selectedMessages.value = {};
                      } else {
                        print('Failed to delete messages');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete messages'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
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
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      _chatService.sendMessage(
                        message,
                        widget.currentUserId!,
                        widget.receiverUserId,
                      );
                      _messageController.clear();
                    }
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
              return ValueListenableBuilder<Set<String>>(
                valueListenable: _selectedMessages,
                builder: (context, selectedMessages, child) {
                  return _buildMessageItem(messages[index], selectedMessages);
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildMessageItem(
      DocumentSnapshot document, Set<String> selectedMessages) {
    Map<String, dynamic> message = document.data() as Map<String, dynamic>;
    final messageId = document.id;
    final isMe = message['senderId'] == widget.currentUserId;
    final decryptedMessage = message['isEncrypted']
        ? EncryptionHelper.decryptMessage(message['message'])
        : message['message'];
    final messageType = message['type'];
    final isLiked = isMessageLiked(message);
    final isMessageSelected = selectedMessages.contains(messageId);

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          _onMessageLongPress(document.id);
        } else if (messageType == "image") {
          Navigator.pushNamed(
            context,
            '/show-image',
            arguments: message['imageUrl'],
          );
        }
      },
      onDoubleTap: () async {
        await toggleLike(document.id);
      },
      onLongPress: () {
        _onMessageLongPress(document.id);
      },
      child: Container(
        width: double.infinity,
        decoration: isMessageSelected
            ? BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
              )
            : null,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(
                    isMe, messageType, decryptedMessage, message),
                if (isLiked)
                  Container(
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: isMe
                        ? const Positioned(
                            bottom: 5.0,
                            right: 5.0,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 15.0,
                            ),
                          )
                        : const Positioned(
                            bottom: -5.0,
                            left: -5.0,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 15.0,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    bool isMe,
    String messageType,
    String decryptedMessage,
    Map<String, dynamic> message,
  ) {
    switch (messageType) {
      case "text":
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: Colors.blue,
            gradient: isMe
                ? const LinearGradient(
                    colors: [AppPallete.gradient1, AppPallete.gradient2],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            decryptedMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      case "image":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: message['imageUrl'],
                height: 200.0,
                width: 200.0,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    SizedBox(
                  height: 50.0,
                  width: 50.0,
                  child: CircularProgressIndicator(
                      value: downloadProgress.progress),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ],
        );
      case "audio":
        return SizedBox(
          width: 200,
          child: CompactAudioPlayerWidget(audioUrl: message['audioUrl']),
        );
      case "document":
        return GestureDetector(
          onTap: () async {
            // Handle document opening
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
        return const Text(
          'File corrupted or not supported',
          style: TextStyle(color: Colors.white),
        );
    }
  }
}
